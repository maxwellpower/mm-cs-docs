# Troubleshooting Steps to Capture and Examine the SAML Response in Mattermost

To help identify and resolve the issue you're experiencing with SAML login in Mattermost, please follow the below steps to capture and analyze the SAML response from your Identity Provider:

---

## **Step 1: Open Mattermost Login Page**

- **Action:** Navigate to your Mattermost login page using your web browser.

---

## **Step 2: Open Developer Tools**

- **Action:** Press **F12** on your keyboard to open the browser's Developer Tools.
    - Alternatively, you can right-click anywhere on the page and select **"Inspect"** or **"Inspect Element"** from the context menu.

---

## **Step 3: Navigate to the Network Tab**

- **Action:** In the Developer Tools window, click on the **"Network"** tab.
    - This tab allows you to monitor all network requests made by the browser.

---

## **Step 4: Start Recording Network Activity**

- **Action:** Ensure that the **"Record"** button (a round button in the upper-left corner of the Network tab) is **red**.
    - If it's **gray**, click it once to start recording network activity.

---

## **Step 5: Preserve the Network Log**

- **Action:** Check the box labeled **"Preserve log"** or **"Persist Logs"**.
    - This ensures that the network requests are retained even if the page redirects during the login process.

---

## **Step 6: Clear Existing Logs**

- **Action:** Click the **"Clear"** button (usually represented by a circle with a line through it or a trash can icon) to remove any existing logs.
    - This helps you focus on the new requests that will be generated during your login attempt.

---

## **Step 7: Perform the SAML Login**

- **Action:** Proceed to log in to Mattermost using the **SAML Single Sign-On (SSO)** option.
    - Enter your credentials when prompted by your Identity Provider.

---

## **Step 8: Filter Network Requests**

- **Action:** After the login attempt, return to the **Network** tab in Developer Tools.
    - In the search or filter box (often labeled **"Filter"**), type **`saml`** to filter and display only the network requests related to SAML.

---

## **Step 9: Locate the SAML Response**

- **Action:** Look for a network request named **`saml`**, **`sso`**, or similar.
    - This request typically corresponds to the SAML response sent from AD FS to Mattermost.

---

## **Step 10: Inspect the Request Payload**

- **Action:** Click on the relevant network request to view its details.
    - In the request details pane, navigate to the **"Headers"**, **"Payload"**, or **"Body"** tab (depending on your browser).
    - Look for a parameter named **`SAMLResponse`**. This is the Base64-encoded SAML assertion.

---

## **Step 11: Copy the SAMLResponse Value**

- **Action:** Right-click on the **`SAMLResponse`** value (the long encoded string).
    - Select **"Copy value"** or **"Copy"** from the context menu to copy the encoded string to your clipboard.

---

## **Step 12: Decode the SAML Assertion**

- **Action:** Use a Base64 decoding tool to decode the SAML assertion.
    - Open a web browser tab and navigate to [https://www.base64decode.org/](https://www.base64decode.org/).
    - In the decoder tool:
        - Paste the copied **`SAMLResponse`** value into the **"Base64 input"** field.
        - Ensure that any spaces or line breaks are removed from the encoded string.
        - Click on the **"Decode"** button to get the XML content of the SAML assertion.

---

## **Step 13: Examine the SAML Assertion**

- **Action:** Review the decoded XML content carefully.
    - **Check for the `NameID` Element:**
        - Look for the `<NameID>` element within the XML. This element should contain the user's identifier (e.g., email or username).
    - **Verify Required Attributes:**
        - Ensure that all necessary attributes are present, such as:
            - **Email Address**
            - **First Name**
            - **Last Name**
            - **Group Memberships** (if applicable)
        - Specifically, look for the **`admin`** attribute or any other custom attributes you expect.

---

## **Step 14: Save the SAML Assertion (Optional)**

- **Action:** If you need to share the SAML assertion with your administrator or support team:
    - Save the decoded XML content to a text file.
    - **Important:** Before sharing, redact or remove any sensitive information to protect user privacy and comply with security policies.

---

## **Additional Notes**

- **Security Reminder:**
    - The SAML assertion contains sensitive information. Handle it with care and do not share it with unauthorized individuals.
- **Browser Variations:**
    - The exact names of tabs and buttons may vary slightly depending on your browser (e.g., Chrome, Firefox, Edge). However, the general process remains the same.
- **If the `NameID` Element is Missing:**
    - This indicates a misconfiguration in the AD FS claims rules. The Identity Provider is not sending the required user identifier.
- **If Required Attributes Are Missing:**
    - Additional claims rules may need to be configured in AD FS to include these attributes in the SAML assertion.
