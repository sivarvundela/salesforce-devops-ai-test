export const PRE_GENERATION_CHECKLIST = `## ⛔ PRE-GENERATION CHECKLIST — run this BEFORE writing your first file

You are about to generate Salesforce metadata. These are the 8 most common errors that cause deployment
failures. Check each one NOW before you start writing, not after.

---

### 1. VF Page references — three-step check BEFORE writing any Apex
Before writing \`Page.XYZ\` anywhere in Apex:
- Is \`XYZ\` listed in Section A (ORG CONTEXT)?  → use it
- Does the task explicitly ask you to create this VF page? → generate BOTH \`.page\` AND \`.page-meta.xml\`. The \`<label>\` element in \`.page-meta.xml\` is **MANDATORY** — omitting it causes the cascade:
  1. \`EnrollmentConfirmationLetter: Required field is missing: label\` → page deploy fails
  2. \`EnrollmentCompletionService: Page EnrollmentConfirmationLetter does not exist\` → Apex compile fails
  3. Every class/Flow referencing that Apex also fails
- Neither? → **remove the \`Page.XYZ\` reference entirely and add to warnings[]**

---

### 2. Method signatures on existing classes
Before calling a method on any class listed in Section A or any class you are NOT generating:
- Does the exact signature (name + parameter types + return type) appear in the ORG CONTEXT? → use it
- Not in ORG CONTEXT? → **add to warnings[], do NOT invent the signature**

---

### 3. @InvocableMethod count
Scan each Apex class you are about to write:
- Does it contain more than one \`@InvocableMethod\`? → **split into separate classes (one per action)**
- The annotation must be \`public static\` and the sole parameter must be \`List<T>\`

---

### 4. LWC template syntax
Before writing any \`.html\` LWC template:
- Every expression must be \`{variableName}\` — **\`{!variableName}\` is Aura syntax and will fail with LWC1210**
- Boolean negation must be a getter in the .js class: \`get hasNoId() { return !this.id; }\`

---

### 5. FlexiPage / CompactLayout / GlobalValueSet element order + names
**FlexiPage:** elements in this exact order:
\`\`\`
flexiPageRegions (all) → masterLabel → parentFlexiPage → sobjectType → template → type
\`\`\`
- Region wrapper: \`<flexiPageRegions>\` — **NOT \`<regions>\`**
- Page-kind element: \`<type>RecordPage</type>\` — **NOT \`<flexiPageType>\`**, always LAST

**CompactLayout:** \`fullName → fields (all) → label\` — \`<label>\` is always LAST after all \`<fields>\`

**GlobalValueSet:** \`customValue (all) → masterLabel → sorted\` — \`<masterLabel>\` is always LAST after all \`<customValue>\` blocks

---

### 6. Layout field uniqueness
Before finalising any .layout-meta.xml:
- List every \`<field>\` value across ALL sections and columns
- Are any duplicated? → **remove the duplicate — each field API name must appear at most once**

---

### 7. Cross-task test class duplication
For Task 2 or later:
- Are you about to write a \`XTest.cls\` for a class that is in Section A (already deployed)? → **do NOT generate it**
- Only generate test classes for the production classes you are ALSO generating in this same response

---

### 8. Bulk test for-each syntax
In every test class that tests bulk data (200 records):
- Use \`for (Integer i = 0; i < 200; i++)\` — **NOT \`for (List<SObject__c> chunk : chunks)\`**
- The \`for (List<X>\` pattern causes: *Unexpected token 'List'* / *Variable does not exist: bulk*

---

After checking all 8 points, proceed to generate files in output contract format.

- Verify Skills Studio Phase 3/4 submit-pr flow (test marker, safe to remove).`.trim();
