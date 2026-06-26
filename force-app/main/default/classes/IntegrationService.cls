/**
 * @description Manages external system integrations with exponential backoff retry logic,
 *              request/response logging, and correlation ID tracking. Implements bulkified
 *              callout patterns and comprehensive error handling.
 */
public with sharing class IntegrationService {
    private static final String LOG_PREFIX = '[IntegrationService]';
    private static final Integer DEFAULT_MAX_RETRIES = 3;
    private static final Integer DEFAULT_INITIAL_BACKOFF_SECONDS = 1;
    private static final Decimal BACKOFF_MULTIPLIER = 2.0;

    /**
     * @description Executes a callout to an external system with exponential backoff retry logic.
     * @param endpoint The URL endpoint to call (should use Named Credential format: callout:CredentialName/path).
     * @param method The HTTP method (GET, POST, PUT, PATCH, DELETE).
     * @param body The request body (for POST/PUT/PATCH requests).
     * @param headers Map of HTTP headers to include in the request.
     * @param maxRetries Maximum number of retry attempts (default: 3).
     * @param initialBackoffSeconds Initial backoff delay in seconds (default: 1).
     * @return HttpResponse containing the response from the external system.
     * @throws IntegrationException When the callout fails after all retries are exhausted.
     */
    public static HttpResponse executeCallout(
        String endpoint,
        String method,
        String body,
        Map<String, String> headers,
        Integer maxRetries,
        Integer initialBackoffSeconds
    ) {
        if (maxRetries == null) maxRetries = DEFAULT_MAX_RETRIES;
        if (initialBackoffSeconds == null) initialBackoffSeconds = DEFAULT_INITIAL_BACKOFF_SECONDS;

        String correlationId = generateCorrelationId();
        Integer currentBackoff = initialBackoffSeconds;
        HttpResponse response = null;
        Exception lastException = null;

        for (Integer attempt = 0; attempt <= maxRetries; attempt++) {
            try {
                response = performCallout(endpoint, method, body, headers, correlationId);
                logResponse(response, correlationId, attempt);
                return response;
            } catch (Exception e) {
                lastException = e;
                logException(e, correlationId, attempt);

                if (attempt < maxRetries) {
                    System.debug(LoggingLevel.WARN, LOG_PREFIX + ' Retrying in ' + currentBackoff + ' seconds (attempt ' + (attempt + 1) + ')...');
                    Long sleepMs = currentBackoff * 1000L;
                    Long startTime = System.currentTimeMillis();
                    while (System.currentTimeMillis() - startTime < sleepMs) {
                    }
                    currentBackoff = (Integer) (currentBackoff * BACKOFF_MULTIPLIER);
                }
            }
        }

        throw new IntegrationException(
            'Callout failed after ' + maxRetries + ' retries to ' + endpoint + ': ' + lastException.getMessage()
        );
    }

    /**
     * @description Performs a single HTTP callout with headers and correlation ID.
     * @param endpoint The URL endpoint.
     * @param method The HTTP method.
     * @param body The request body.
     * @param headers Map of HTTP headers.
     * @param correlationId Unique correlation ID for tracking.
     * @return HttpResponse from the callout.
     */
    private static HttpResponse performCallout(
        String endpoint,
        String method,
        String body,
        Map<String, String> headers,
        String correlationId
    ) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(method);
        if (body != null && (method.equalsIgnoreCase('POST') || method.equalsIgnoreCase('PUT') || method.equalsIgnoreCase('PATCH'))) {
            request.setBody(body);
        }
        if (headers != null) {
            for (String key : headers.keySet()) {
                request.setHeader(key, headers.get(key));
            }
        }
        request.setHeader('X-Correlation-ID', correlationId);
        request.setTimeout(120000);

        HttpResponse response = http.send(request);
        return response;
    }

    /**
     * @description Generates a unique correlation ID for request tracking.
     * @return String correlation ID.
     */
    private static String generateCorrelationId() {
        return System.now().formatGmt('yyyyMMddHHmmssSSS') + '-' + Math.random().toString().substring(2, 10);
    }

    /**
     * @description Logs the HTTP response.
     * @param response The HttpResponse to log.
     * @param correlationId The correlation ID.
     * @param attempt The attempt number.
     */
    private static void logResponse(HttpResponse response, String correlationId, Integer attempt) {
        System.debug(
            LoggingLevel.INFO,
            LOG_PREFIX + ' [' + correlationId + '] Attempt ' + (attempt + 1) + ' - Status: ' + response.getStatusCode()
        );
    }

    /**
     * @description Logs exceptions encountered during callout.
     * @param e The exception to log.
     * @param correlationId The correlation ID.
     * @param attempt The attempt number.
     */
    private static void logException(Exception e, String correlationId, Integer attempt) {
        System.debug(
            LoggingLevel.ERROR,
            LOG_PREFIX + ' [' + correlationId + '] Attempt ' + (attempt + 1) + ' failed: ' + e.getMessage() + ' ' + e.getStackTraceString()
        );
    }

    /**
     * @description Custom exception for integration errors.
     */
    public class IntegrationException extends Exception {
    }
}
