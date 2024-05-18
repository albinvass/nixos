;; extends
(block_mapping_pair
  key: (flow_node)
  value: (block_node
      (block_scalar
        (comment) @injection.language
        (#gsub! @injection.language "#%s*([%w%p]+)%s*" "%1")
        ) @injection.content)
  )
