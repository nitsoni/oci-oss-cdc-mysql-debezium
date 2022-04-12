## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "template_file" "kafka_connector_config" {

  depends_on = [oci_core_instance.compute_instance, oci_streaming_connect_harness.connect_harness, oci_streaming_stream_pool.debezium_cdc]

  template = file("./config/connect-distributed.properties")

  vars = {
    REGION               = var.region
    CONNECT_HARNESS_OCID = oci_streaming_connect_harness.connect_harness.id
    TENANCY_NAME         = data.oci_identity_tenancy.current_user_tenancy.name
    USER_NAME            = data.oci_identity_user.current_user.name
    AUTH_CODE            = oci_identity_auth_token.stream_auth_token.token
    STREAM_POOL          = oci_streaming_stream_pool.debezium_cdc.id
  }
}

data "template_file" "debezium_connector_config" {

  depends_on = [oci_core_instance.compute_instance, oci_streaming_connect_harness.connect_harness, oci_streaming_stream_pool.debezium_cdc]

  template = file("./config/connector.json")

  vars = {
    REGION         = var.region
    TENANCY_NAME   = data.oci_identity_tenancy.current_user_tenancy.name
    USER_NAME      = data.oci_identity_user.current_user.name
    AUTH_CODE      = oci_identity_auth_token.stream_auth_token.token
    STREAM_POOL    = oci_streaming_stream_pool.debezium_cdc.id
    MYSQL_USERNAME = var.admin_username
    MYSQL_PASS     = var.admin_password
  }
}

resource "null_resource" "run_scripts" {

  depends_on = [oci_core_instance.compute_instance, oci_streaming_stream_pool.debezium_cdc, oci_streaming_connect_harness.connect_harness]

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.compute_instance.public_ip
      private_key = var.generate_public_ssh_key ? tls_private_key.public_private_key_pair.private_key_pem : file(var.private_ssh_key_path)
      agent       = false
      timeout     = "10m"
    }
    content     = data.template_file.kafka_connector_config.rendered
    destination = "/home/opc/connect-distributed.properties"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.compute_instance.public_ip
      private_key = var.generate_public_ssh_key ? tls_private_key.public_private_key_pair.private_key_pem : file(var.private_ssh_key_path)
      agent       = false
      timeout     = "10m"
    }
    content     = data.template_file.debezium_connector_config.rendered
    destination = "/home/opc/connector.json"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.compute_instance.public_ip
      private_key = var.generate_public_ssh_key ? tls_private_key.public_private_key_pair.private_key_pem : file(var.private_ssh_key_path)
      agent       = false
      timeout     = "10m"
    }

    inline = [
      "sudo yum install java-1.8.0-openjdk.x86_64 -y",
      "wget https://archive.apache.org/dist/kafka/2.5.1/kafka_2.12-2.5.1.tgz",
      "tar -xvf kafka_2.12-2.5.1.tgz",
      "mv kafka_2.12-2.5.1 kafka",
      "wget https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/1.2.5.Final/debezium-connector-mysql-1.2.5.Final-plugin.tar.gz",
      "tar -xvf debezium-connector-mysql-1.2.5.Final-plugin.tar.gz",
      "cp debezium-connector-mysql/*.jar kafka/libs/",
      "echo 'Downloading sample employee DB.'",
      "wget https://github.com/datacharmer/test_db/releases/download/v1.0.7/test_db-1.0.7.tar.gz",
      "tar -xvf test_db-1.0.7.tar.gz",
      "sleep 5",
      "sudo yum install mysql -y",
      "mysql --host 10.0.1.3 -u ${var.admin_username} --password=${var.admin_password} -e \"ALTER USER '${var.admin_username}'@'%' IDENTIFIED WITH mysql_native_password BY '${var.admin_password}';\""
    ]
  }


}

