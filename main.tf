
resource "aws_cloudfront_distribution" "cf_distribution" {
  enabled             = var.enable
  is_ipv6_enabled     = var.is_ipv6_enabled
  comment             = var.comment
  default_root_object = var.default_root_object

  ## Origin's
  # S3 block
  dynamic "origin" {
    for_each = [for o in var.s3_origin_configs : merge({
      domain_name            = o.domain_name
      origin_id              = o.origin_id
      origin_path            = o.origin_path
      origin_access_identity = o.origin_access_identity
    }, try({ custom_headers = o.custom_headers }, {}))]
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id
      origin_path = origin.value.origin_path

      dynamic "custom_header" {
        for_each = try([for h in origin.value.custom_headers : {
          name  = h.name
          value = h.value
        }], [])

        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      s3_origin_config {
        origin_access_identity = origin.value.origin_access_identity
      }
    }
  }
  # Custom block
  dynamic "origin" {
    for_each = [for o in var.custom_origin_configs : {
      domain_name              = o.domain_name
      origin_id                = o.origin_id
      origin_path              = o.origin_path
      custom_headers           = o.custom_headers
      http_port                = o.http_port
      https_port               = o.https_port
      origin_keepalive_timeout = o.origin_keepalive_timeout
      origin_read_timeout      = o.origin_read_timeout
      origin_protocol_policy   = o.origin_protocol_policy
      origin_ssl_protocols     = o.origin_ssl_protocols

    }]
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id
      origin_path = origin.value.origin_path

      dynamic "custom_header" {
        for_each = [for h in origin.value.custom_headers : {
          name  = h.name
          value = h.value
        }]

        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      custom_origin_config {
        http_port                = origin.value.http_port
        https_port               = origin.value.https_port
        origin_keepalive_timeout = origin.value.origin_keepalive_timeout
        origin_read_timeout      = origin.value.origin_read_timeout
        origin_protocol_policy   = origin.value.origin_protocol_policy
        origin_ssl_protocols     = origin.value.origin_ssl_protocols
      }
    }
  }

  # Optional
  dynamic "logging_config" {
    for_each = local.cloudfront_logging_configs[local.enable_logging]
    content {
      bucket          = logging_config.value.bucket
      include_cookies = logging_config.value.include_cookies
      prefix          = logging_config.value.prefix
    }
  }

  aliases = var.aliases

  default_cache_behavior {
    allowed_methods  = var.default_cache_behavior["allowed_methods"]
    cached_methods   = var.default_cache_behavior["cached_methods"]
    target_origin_id = var.default_cache_behavior["target_origin_id"]

    dynamic "lambda_function_association" {
      for_each = try([for i in var.default_cache_behavior["lambda_association"] : {
        event_type   = i.event_type
        lambda_arn   = i.lambda_arn
        include_body = i.include_body
      }], [])

      content {
        event_type   = lambda_function_association.value.event_type
        lambda_arn   = lambda_function_association.value.lambda_arn
        include_body = lambda_function_association.value.include_body
      }
    }

    forwarded_values {
      query_string = var.default_cache_behavior["query_string"]
      headers      = var.default_cache_behavior["headers"]

      cookies {
        forward = var.default_cache_behavior["forward"]
      }
    }

    viewer_protocol_policy = var.default_cache_behavior["viewer_protocol_policy"]
    min_ttl                = var.default_cache_behavior["min_ttl"]
    default_ttl            = var.default_cache_behavior["default_ttl"]
    max_ttl                = var.default_cache_behavior["max_ttl"]
  }


  dynamic "ordered_cache_behavior" {

    for_each = [for s in var.ordered_cache_behavior_variables : {
      path_pattern           = s.path_pattern
      allowed_methods        = s.allowed_methods
      cached_methods         = s.cached_methods
      target_origin_id       = s.target_origin_id
      viewer_protocol_policy = s.viewer_protocol_policy
      query_string           = s.query_string
      headers                = s.headers
      forward                = s.forward
      min_ttl                = s.min_ttl
      default_ttl            = s.default_ttl
      max_ttl                = s.max_ttl
      compress               = s.compress
      lambda_association     = s.lambda_association
    }]

    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      allowed_methods  = ordered_cache_behavior.value.allowed_methods
      cached_methods   = ordered_cache_behavior.value.cached_methods
      target_origin_id = ordered_cache_behavior.value.target_origin_id

      dynamic "lambda_function_association" {
        for_each = [for i in ordered_cache_behavior.value.lambda_association : {
          event_type   = i.event_type
          lambda_arn   = i.lambda_arn
          include_body = i.include_body
        }]

        content {
          event_type   = lambda_function_association.value.event_type
          lambda_arn   = lambda_function_association.value.lambda_arn
          include_body = lambda_function_association.value.include_body
        }
      }

      forwarded_values {
        query_string = ordered_cache_behavior.value.query_string
        headers      = ordered_cache_behavior.value.headers

        cookies {
          forward = ordered_cache_behavior.value.forward
        }
      }

      min_ttl                = ordered_cache_behavior.value.min_ttl
      default_ttl            = ordered_cache_behavior.value.default_ttl
      max_ttl                = ordered_cache_behavior.value.max_ttl
      compress               = ordered_cache_behavior.value.compress
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy

    }
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = var.restriction_type
      locations        = var.locations
    }
  }

  # Optional certificate
  dynamic "viewer_certificate" {
    for_each = local.acm_certificate_arn_configs[local.enable_certificate]
    content {
      acm_certificate_arn            = viewer_certificate.value.acm_certificate_arn
      minimum_protocol_version       = viewer_certificate.value.minimum_protocol_version
      ssl_support_method             = viewer_certificate.value.ssl_support_method
      cloudfront_default_certificate = viewer_certificate.value.cloudfront_default_certificate
    }
  }

  web_acl_id = var.waf_web_acl_id

  tags = var.tags

  lifecycle {
    ignore_changes = [default_cache_behavior[0].lambda_function_association, web_acl_id]
  }
}
