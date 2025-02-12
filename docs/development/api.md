# API Reference

## Chat API

### Send Message
```http
POST /api/chat/completions
Content-Type: application/json

{
  "model": "model_name",
  "messages": [
    {
      "role": "user",
      "content": "Hello!"
    }
  ]
}
```

### List Models
```http
GET /api/models
```

## Authentication

### Get Token
```http
POST /api/auth/token
Content-Type: application/json

{
  "username": "user",
  "password": "pass"
}
```

## Model Management

### List Local Models
```http
GET /api/ollama/tags
```

### Pull Model
```http
POST /api/ollama/pull
Content-Type: application/json

{
  "name": "model_name"
}
```

For complete OpenAPI specification, see our [Swagger Documentation](https://api.example.com/docs).
