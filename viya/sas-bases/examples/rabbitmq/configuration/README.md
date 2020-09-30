# Configuration Settings for RabbitMQ

## Overview

This readme describes the settings available for deploying RabbitMQ.

## Installation

Based on the following description of different example files, determine if you want to use any example file in your deployment. If you do, copy the example file and place it in your site-config directory.

Each file has information about its content. The variables in the file are set off by curly braces and spaces, such as {{ NUMBER-OF-NODES }}. Replace the entire variable string, including the braces, with the value you want to use.

After you have edited the file, add a reference to it in the transformer block of the base kustomization.yaml file.

## Examples

The example files are located at /$deploy/sas-bases/examples/rabbitmq/configure. The following is a list of each example file for RabbitMQ settings and the file name.

- specify the number of RabbitMQ nodes in the cluster (rabbitmq-node-count.yaml) **Note**: The default number of nodes is three. SAS recommends a node count that is odd such as 1,3, or 5.
- modify the resource allocation for RAM (rabbitmq-modify-memory.yaml)
- modify the persitent volume claim size for nodes (rabbitmq-modify-pvc-size.yaml)