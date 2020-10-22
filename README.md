# MMS_Helper

Some glue code to simplify the use of the Open Horizon Model Management System.

1. Begin by installing the Open-Horizon Agent, and configuring your creds:

``` bash
   $ agent-install.sh
   $ export HZN_ORG_ID=...
   $ export HZN_EXCHANGE_USER_AUTH=...
```

2. Edit the Makefile variables below as described:

   `YOUR_SERVICE_NAME` - the name of your dependent MMS consuming Service

   `YOUR_SERVICE_VERSION` - the version of your dependent MMS consuming Service

   `MMS_HELPER_SHARED_VOLUME`  - a Docker volume for these conainers to share.

     Note that if you use a host **directory** here instead of a **volume name**,
     then you need to ensure the directory is writeable by the contaiiner
     processes (which run under a different user ID).
   
     Note also that you need to mount this in your consuming Service, e.g., in
     you Service defiinition's **deployment string**, use something to the binding
     shown below. Please see the [deployment string documentation](https://github.com/open-horizon/anax/blob/master/docs/deployment_string.md) for more details.
     
``` bash
       "binds": ["$MMS_HELPER_SHARED_VOLUME:/CONTAINER_DIR:ro"]
```

   `YOUR_OBJECT_TYPE` - the object type name for MMS_Helper to monitor

   `YOUR_DOCKERHUB_ID` - your DockerHub account name for image "push" commands
     Note: you need to `docker login` to this before pushing or publishing

3. Build, push and publish this "mms-helper" service:

``` bash
   $ make build
   $ docker login -u ...
   $ make push
   $ make publish-service
```

4. Publish a pattern or business policy to deploy this Service. E.g.:

``` bash
   $ make publish-pattern
```

5. Register your edge nodes using a pattern or node policy, e.g.:

``` bash
   $ make register-pattern
```

6. Start using the `hzn mms object publish` command to publish objects of the specified `YOUR_OBJECT_TYPE`. They will show up up in your `/CONTAINER_DIR` within your container, named using the object IDs you published them with, If you used the pattern above, and set the `OPTIONAL_...` variables, then simply:

``` bash
   $ make publish-object
```

 to send the example file object to your dependendency Service running on
 every node registered with the example pattern.

