#!/bin/bash

ip link add name veth0 type veth peer name veth1
ip link add name veth2 type veth peer name veth3
ip link add name veth4 type veth peer name veth5
ip link set dev veth0 up
ip link set dev veth1 up
ip link set dev veth2 up
ip link set dev veth3 up
ip link set dev veth4 up
ip link set dev veth5 up