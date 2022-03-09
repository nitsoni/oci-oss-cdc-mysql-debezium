## Copyright (c) 2020, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_streaming_stream_pool" "debezium_cdc" {
  compartment_id = var.compartment_ocid
  name           = "debezium_cdc_pool"

  kafka_settings {
    auto_create_topics_enable = true
    num_partitions = 1
  }
}

resource "oci_streaming_stream" "mysql_employees" {
    #Required
    name = "employees_schema_changes"
    partitions = 1

    stream_pool_id = oci_streaming_stream_pool.debezium_cdc.id
}


resource "oci_streaming_connect_harness" "connect_harness" {
  compartment_id = var.compartment_ocid
  name           = "debezium-connect-harness"
}
