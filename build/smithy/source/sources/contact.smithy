$version: "2"

namespace com.example.contacts

use aws.protocols#restJson1
use smithy.api#paginated
use smithy.api#readonly

@restJson1
service ContactService {
    version: "2026-11-05"
    operations: [
        CreateContact
        CheckContactExists
        ListContacts
    ]
}

// === DATA TYPES ===
@pattern("^[6-9][0-9]{9}$")
string MobileNumber

@length(min: 1, max: 100)
string ContactName

// === 1. CREATE CONTACT ===
/// This operation creates a new contact
@http(method: "POST", uri: "/v1/contacts", code: 201)
@examples([
    {
        title: "Create a New Contact",
        documentation: "This example shows How to create a valid contact",
        input: {
            mobileNumber: "9876512345",
            name:"Smith"
        },
        output: {
            mobileNumber: "9876512345",
            name:"Smith"
        }
    }
])
operation CreateContact {
    input: CreateContactInput
    output: CreateContactOutput
    errors: [
        ValidationException
        ConflictException
    ]
}

structure CreateContactInput {
    @required
    mobileNumber: MobileNumber

    @required
    name: ContactName
}

structure CreateContactOutput {
    @required
    mobileNumber: MobileNumber

    @required
    name: ContactName
}

// === 2. CHECK IF MOBILE NUMBER EXISTS ===
/// This operation checks if mobile number already exist
@readonly
@http(method: "GET", uri: "/v1/contacts/{mobileNumber}", code: 200)
operation CheckContactExists {
    input: CheckContactExistsInput
    output: CheckContactExistsOutput
    errors: [
        ResourceNotFoundException
        ValidationException
    ]
}

structure CheckContactExistsInput {
    @required
    @httpLabel
    mobileNumber: MobileNumber
}

structure CheckContactExistsOutput {
    @required
    exists: Boolean

    @required
    mobileNumber: MobileNumber

    name: ContactName
}

// === 3. LIST ALL CONTACTS ===
/// This operation list all contacts
@readonly
@paginated(inputToken: "nextToken", outputToken: "nextToken", items: "items", pageSize: "maxResults")
@http(method: "GET", uri: "/v1/contacts", code: 200)
operation ListContacts {
    input: ListContactsInput
    output: ListContactsOutput
}

structure ListContactsInput {
    @httpQuery("maxResults")
    maxResults: Integer

    @httpQuery("nextToken")
    nextToken: String
}

structure ListContactsOutput {
    @required
    items: ContactList

    nextToken: String
}

list ContactList {
    member: ContactSummary
}

structure ContactSummary {
    @required
    mobileNumber: MobileNumber

    @required
    name: ContactName
}

// === ERRORS ===
@error("client")
@httpError(400)
structure ValidationException {
    @required
    message: String
}

@error("client")
@httpError(404)
structure ResourceNotFoundException {
    @required
    message: String
}

@error("client")
@httpError(409)
structure ConflictException {
    @required
    message: String
}

