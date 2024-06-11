;; extends
(block_sequence_item
  (block_node
    (block_mapping
      (block_mapping_pair
	key:
	  (flow_node
	    ((plain_scalar) @task_module
		(#eq? @task_module
		"shell")) @shell
          )
	value:
	  (block_node
	    (block_scalar) @injection.content
	    (#set! injection.language "bash")
	    (#set! injection.include-children)
	  )
      )
    )
  )
)
