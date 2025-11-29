/// Output format options for schema generation.
enum SpectraFormat {
  /// JSON Schema (Draft 2020-12)
  jsonSchema,

  /// OpenAPI 3.x specification
  openApi,

  /// Protocol Buffers (.proto)
  protobuf,
}

/// String format hints for schema generation.
///
/// These correspond to JSON Schema format keywords and similar concepts
/// in other schema formats.
enum StringFormat {
  /// RFC 5321 email address
  email,

  /// RFC 3986 URI
  uri,

  /// RFC 3986 URI reference
  uriReference,

  /// RFC 4122 UUID
  uuid,

  /// RFC 3339 date-time
  dateTime,

  /// RFC 3339 date
  date,

  /// RFC 3339 time
  time,

  /// ISO 8601 duration
  duration,

  /// IPv4 address
  ipv4,

  /// IPv6 address
  ipv6,

  /// Hostname
  hostname,

  /// JSON Pointer
  jsonPointer,

  /// Relative JSON Pointer
  relativeJsonPointer,

  /// Regular expression
  regex,
}
