# Repository rules

- Keep this image application-agnostic: it is shared by many unrelated services.
- Application-specific paths, upstreams, redirects, rewrites and protocol behavior must
  be optional configuration with backward-compatible defaults; never hardcode a
  Seafile-specific route or policy into the image.
- Examples in documentation may name a concrete application, but the underlying image
  contract and Nginx template must remain generic.
