# Step 0

```shell
mkdir <proj-name>
cd <proj-name>
```

# Step 1 : Install Smithy CLI

## Mac

brew tap smithy-lang/tap && brew install smithy-cli

## For other

Visit https://smithy.io/2.0/guides/smithy-cli/cli_installation.html

# Step 2 : OpenAPI.json generation

- Create `smithy-build.json` file, primary configuration file used by Smithy-Build
- Create a folder `smithy-model`
- Inside `smithy-model` folder create a smithy file, say `contact.smithy`
- Now execute following in a terminal inside <proj-name> folder

```shell
smithy format
smithy validate
smithy build
```

- This will generate a file `./build/smithy/source/openapi/ContactService.openapi.json` as per ContactService

# Step 3: ContactService.openapi.json linting using Spectral

- Install spectral cli globally

```shell
npm install -g @stoplight/spectral-cli
```

- Create `spectral-rules.yaml`
- apply

```shell
spectral lint ./build/smithy/source/openapi/ContactService.openapi.json --ruleset spectral-rules.yaml
```

# Step 4: Backend part

- Use datamodel-code-generator directly to output strictly typed models.py (DTOs/Contracts),
- - Install datamodel-code-generator As a global standalone CLI

```shell
uv tool install datamodel-code-generator
```

- Create FastAPI Project (if not already)
- - make sure you are inside <proj-name> directory
    cd <proj-name>
    uv init backend --bare
    cd backend
    uv add "fastapi[standard]"
    uv add pydantic
    mkdir src
    mkdir src/domain
    mkdir src/domain/schemas
    cd to <proj-name>
- - Again, make sure you are inside <proj-name> directory
- Generate domain schema

```shell
datamodel-codegen \
  --input ./build/smithy/source/openapi/ContactService.openapi.json \
  --input-file-type openapi \
  --output backend/src/domain/schemas/dto.py \
  --output-model-type pydantic_v2.BaseModel \
  --target-python-version 3.11 \
  --use-annotated \
  --use-standard-collections \
  --use-union-operator \
  --field-constraints \
  --collapse-root-models \
  --strict-nullable \
  --snake-case-field \
  --capitalise-enum-members
```

# Step 5: Mock Server

- Install Prism cli

```shell
  npm install -g @stoplight/prism-cli
```

- In a new terminal

```shell
  cd <proj-name>
  prism mock ./build/smithy/source/openapi/ContactService.openapi.json
```

- - This will start server at http://localhost:4010

# Step 6: Schemathesis Based API Testing

- Install globally

```shell
uv tool install schemathesis
```

- run

```shell
uvx schemathesis run ./build/smithy/source/openapi/ContactService.openapi.json --url http://localhost:4010 --report-json-path ./report.json

```

# Step 7: Using openapi-generator-cli to generate API client SDKs
- Install globally
```shell
npm install -g @openapitools/openapi-generator-cli
npm config set allow-scripts=@openapitools/openapi-generator-cli --location=user
or
brew install openapi-generator
```
- Create a nextjs app (if not already)
npx create-next-app@latest
name: frontend
- cd <proj-name>
openapi-generator-cli generate \
  -i ./build/smithy/source/openapi/ContactService.openapi.json \
  -g typescript-axios \
  -o ./frontend/generated-client
or
openapi-generator generate \
  -i ./build/smithy/source/openapi/ContactService.openapi.json \
  -g typescript-axios \
  -o ./frontend/generated-client

# Step 8 : Use generated Client
```typescript
// src/lib/api.ts
import { paths } from "@/types/api";
import createClient from "openapi-fetch"; // Optional lightweight wrapper
export const client = createClient<paths>({ baseUrl: "https://example.com" });
```

# Using openapi-generator-cli 
- Configure the API Client Instance
```typescript
import { Configuration, DefaultApi } from '@/generated-client';
// Use environment variables for the API base URL
const apiConfig = new Configuration({
  basePath: process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000',
  // You can also add default headers, API keys, or middleware here
});

// Export a pre-configured instance of the API
export const contactsApi = new DefaultApi(apiConfig);
```
- Use the Client in a Next.js Component
```typescript
// app/contacts/page.tsx
import { contactsApi } from '@/lib/api';

export default async function ContactsPage() {
  let contacts = [];
  
  try {
    // Call the generated API method
    const response = await contactsApi.getContacts();
    contacts = response.data; // typescript-axios wraps the payload in .data
  } catch (error) {
    console.error('Failed to fetch contacts:', error);
  }

  return (
    <main className="p-6">
      <h1 className="text-2xl font-bold mb-4">Contacts</h1>
      <ul className="space-y-2">
        {contacts.map((contact: any) => (
          <li key={contact.id} className="p-4 border rounded shadow-sm">
            {contact.name} ({contact.email})
          </li>
        ))}
      </ul>
    </main>
  );
}
```
- Handle Authentication and Interceptors
```typescript
import { Configuration, DefaultApi } from '@/generated-client';
import axios from 'axios';

// Create a custom Axios instance if you need advanced interceptors
const axiosInstance = axios.create({
  baseURL: 'https://api.yourdomain.com',
  withCredentials: true, // if using cookie-based auth
});

// Add an auth interceptor if using localStorage/tokens
axiosInstance.interceptors.request.use((config) => {
  const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

const apiConfig = new Configuration();
export const contactsApi = new DefaultApi(apiConfig, undefined, axiosInstance);
```

