# APIService

`APIService` is a library that provides a basic HTTP request layer in Swift, using Swift Concurrency.

It allows you to enable **SSL pinning** for checking server certificates' public keys against local ones (either key hashes -base64 encoded strings- or `DER` certificates).

## Basic structure

The basic object for the library is `API`, which conforms to the `APIService` protocol. `APIService` extends from `Sendable` and is value type (`struct`).

The protocol provides several methods that conform to Swift Concurrency (`async throws`), being `perform(_:validatesStatusCode:)` the most important one, because it allows you to decode the returned `Data` by yourself (or ignore it if you don't expect to get a response body) and handle HTTP response codes manually, if you want to.

Other methods are the usual ones:

- `delete<Output: Decodable>(_:) async throws(APIError) -> Output`
- `get<Output: Decodable>(_:) async throws(APIError) -> Output`
- `post<Output: Decodable>(_:,parameters:) async throws(APIError) -> Output`
- `put<Output: Decodable>(_:,parameters:) async throws(APIError) -> Output`

Note that all these methods (except for the `perform(_:validatesStatusCode:)` one) validate the HTTP status code from the network response. If they are not in the `validStatusCodes` array from the `API` (specified at initialization), then the network request will fail, throwing the corresponding `APIError`.

The `perform(_:validatesStatusCode:)` method will check out the HTTP response codes (when `validatesStatusCode` is `true`), or not (when `validatesStatusCode` is `false`). These valid status codes are passed at the `API` initialization.

As they're generic methods, you need to specify the `Decodable` type you expect to get as a response:

```
struct MyResponseType: Decodable {
    let id: Int
    let name: String
}

Task {
    let url = URL(string: "https://...")!
    do {
        let response: MyResponseType = try await api.get(url)

        // or:
        // let response = try await api.get(url) as MyResponseType

        print("The response is: \(response)
    } catch {
        print("There was an error: \(error)
    }
}
```

## Initialization

To instantiate the API, you can use the `API(sslPinning:validStatusCodes:baseHeaders:)` init.

### Parameters

| Parameter | Type | Default value | Description |
| --- | --- | --- | --- |
| `sslPinning` | `API.SSLPinning` | `.disabled` | Defines the type of SSL pinning to be used in network requests. Possible values are `.enabledWithCertificateURLs(_ urls: [URL])`, `.enabledWithKeyHashes(_ hashes: [String])` and `.disabled`. |
| `validStatusCodes` | `[Int]` | `Array(200...299)` | Defines the HTTP response status codes to be considered valid. If the status code is not inside this array, then the network request will fail and throw the corresponding `APIError`. Note that cerver certificates' public keys will be tested against all public keys or hashes provided. If there's one matching, the network request will succeed, or fail otherwise. |
| `baseHeaders` | `[String: String]?` | `nil` | All network requests made using this specific API instance will include these headers. If the same header is used as a parameter of any of the public methods (request, get, post, etc.), then the method parameter takes priority over this default value. |

#### Base Headers

If you instantiate the API like this:

```
let api: APIService = API(
    baseHeaders: [
        "hello": "world",
        "bye": "galaxy"
    ]
)
```

And you make a network request like this:

```
let url = URL(string: "https://somedomain.com/path")!
let response: SomeDecodableType = try await api.get(
    url,
    headers: [
        "hello": "iOS", // overrides the baseHeaders "hello" one
        "farewell": "universe"
    ]
)
```

Then the headers that will be used for this network request will be:

```
[
    "hello": "iOS",
    "bye": "galaxy",
    "farewell": "universe"
]
```

## API usage example

1) With DER certificate (`Certificate.der`):

```
let certificateURL = Bundle.main.url(for: "Certificate", withExtension: "der")!
let api: APIService = API(
    sslPinning: .enabledWithCertificateURLs([certificateURL]),
    validStatusCodes: [200, 204]
)
```

2) With base64 hashes from public keys:

```
let api: APIService = API(
    sslPinning: .enabledWithKeyHashes([
        "some base64 encoded hash for the public key"
    ])
)
```

## Demo
You can check out the [Demo App](https://github.com/alejandroivan/APIServiceExample) to see how it works.