#!/bin/bash

if [ -f /etc/nagios/conf.d/hosts.cfg ]; then
   mv /etc/nagios/conf.d/hosts.cfg /etc/nagios/conf.d/hosts.cfg.bk
   touch /etc/nagios/conf.d/hosts.cfg
else
   touch /etc/nagios/conf.d/hosts.cfg
fi
# Constants
HOSTS_CFG="/etc/nagios/conf.d/hosts.cfg"

# Function to append a host definition
append_host_definition() {
    local TEMPLATE_NAME="PARAM ARYABHATTA"

    # Host definition block
    HOST_DEFINITION=$(cat <<EOF
define host{
        name ${TEMPLATE_NAME} ; Name of this template
        use generic-host ; Inherit default values
        check_period 24x7
        check_interval 5
        retry_interval 1
        max_check_attempts 10
        check_command check-host-alive
        notification_period 24x7
        notification_interval 30
        notification_options d,r
        contact_groups admins
        register 1 ; DONT REGISTER THIS - ITS A TEMPLATE
}
EOF
    )

    # Append to hosts.cfg
    echo "$HOST_DEFINITION" >> "$HOSTS_CFG"
    echo "Host definition for '${TEMPLATE_NAME}' successfully appended to $HOSTS_CFG"
}

# Main function to prompt for inputs and execute Python script for multiple node types
# Main function to prompt for inputs and execute Python script for multiple node types
main() {
    # Ensure the file exists
    if [[ ! -f $HOSTS_CFG ]]; then
        echo "Error: $HOSTS_CFG does not exist. Creating the file."
        touch $HOSTS_CFG
    fi

    # Prompt for the Template Name
    read -e -p "Enter the Template Name: " TEMPLATE_NAME
    append_host_definition "${TEMPLATE_NAME}"

    # Arrays of node types
    NODE_TYPES1=("master" "management" "login")
    NODE_TYPES2=("compute" "high memory" "gpu")

    # Iterate over each node type in NODE_TYPES1
    for NODE_TYPE in "${NODE_TYPES1[@]}"; do
        echo "Adding definition for ${NODE_TYPE} in /etc/nagios/conf.d/hosts.cfg"
        python3 add_service_node_def.py "${HOSTS_CFG}" "${TEMPLATE_NAME}" --node_type "${NODE_TYPE}"
        if [[ $? -ne 0 ]]; then
            echo "Error while adding definition for ${NODE_TYPE}. Please check add_service_node_def.py."
            exit 1
        fi
        echo "${NODE_TYPE} completed successfully."
    done

    # Iterate over each node type in NODE_TYPES2
    for NODE_TYPE in "${NODE_TYPES2[@]}"; do
        echo "Adding definition for ${NODE_TYPE} in /etc/nagios/conf.d/hosts.cfg"
        python3 add_compute_node_def.py "${HOSTS_CFG}" "${TEMPLATE_NAME}" --node_type "${NODE_TYPE}"
        if [[ $? -ne 0 ]]; then
            echo "Error while adding definition for ${NODE_TYPE}. Please check add_compute_node_def.py."
            exit 1
        fi
        echo "${NODE_TYPE} completed successfully."
    done

    echo "All host definitions added successfully."
}


# Execute main function
main
