/**
 * Client for interacting with the server.
 */
IDEALS.Client = function() {

    const ROOT_URL = $("input[name=root_url]").val();
    const CSRF_TOKEN = $("meta[name=csrf-token]").attr("content");

    const self = this;

    /**
     * Sends an HTTP DELETE request to the given URI.
     *
     * @param uri {String}
     * @param onSuccess {Function}
     * @param onError {Function}
     */
    this.delete = function (uri, onSuccess, onError) {
        $.ajax({
            type: "DELETE",
            url: uri,
            headers: {"X-CSRF-Token": CSRF_TOKEN},
            success: onSuccess,
            error: onError
        });
    };

    /**
     * @param unitID {Number}
     * @param onlySubmitterAccess {Boolean}
     * @param onSuccess {Function} Function accepting response data.
     */
    this.fetchUnitCollections = function (unitID, onlySubmitterAccess, onSuccess) {
        var url = ROOT_URL + "/units/" + unitID +
            "/collections-tree-fragment?for-select=true";
        if (onlySubmitterAccess) {
            url += "&only-submitter-access=true"
        }
        $.ajax({
            method: "GET",
            url:    url,
            headers: {"X-CSRF-Token": CSRF_TOKEN},
            success: onSuccess
        });
    };

    /**
     * @param query {String}
     * @param scoped {Boolean} Whether to scope the results to the current
     *                         institution.
     * @param onSuccess {Function} Function accepting response data.
     * @return
     */
    this.fetchUsers = function(query, scoped, onSuccess) {
        const MAX_RESULTS = 8;
        const PATH        = scoped ? "/users" : "/all-users";
        $.ajax({
            url: ROOT_URL + PATH + ".json?window=" + MAX_RESULTS + "&q=" + query,
            method: "get",
            success: function (data, status, xhr) {
                if (onSuccess) {
                    onSuccess(data, status, xhr);
                }
            }
        });
    };

    /**
     * Sends an message to Medusa to ingest a file that exists in staging.
     *
     * @param uri [String]         Bitstream URI.
     * @param onSuccess {Function} Function accepting a string argument.
     *                             The string is the URI of the created
     *                             bitstream.
     * @param onError {Function}   Function accepting an {XMLHttpRequest}
     *                             argument.
     */
    this.post = function (uri, onSuccess, onError) {
        $.ajax({
            type: "POST",
            url: uri,
            headers: {"X-CSRF-Token": CSRF_TOKEN},
            success: onSuccess,
            error: onError
        });
    };

    /**
     * Creates a new Bitstream attached to an Item on the server, and
     * uploads data to it.
     *
     * The upload process is documented in the BitstreamsController class.
     *
     * @param file {File}                  File to upload.
     * @param item_id {Number}             ID of the owning item.
     * @param onProgressChanged {Function} Function accepting an event
     *                                     argument.
     * @param onSuccess {Function}         Function accepting a string
     *                                     argument. The string is the URI
     *                                     of the created bitstream.
     * @param onError {Function}           Function accepting a string
     *                                     message and an {XMLHttpRequest}
     *                                     argument.
     */
    this.uploadFile = function (file, item_id, onProgressChanged, onSuccess,
                                onError) {
        /**
         * Sends a POST request to create a Bitstream.
         */
        const createBitstream = function () {
            $.ajax({
                method: "POST",
                headers: {"X-CSRF-Token": CSRF_TOKEN},
                url: ROOT_URL + "/items/" + item_id + "/bitstreams",
                data: {
                    bitstream: {
                        filename: file.name,
                        length: file.size
                    }
                },
                success: function (data, status, xhr) {
                    fetchRepresentation(xhr.getResponseHeader("Location"));
                },
                error: function (data, status, xhr) {
                    onError(null, xhr);
                }
            });
        }

        /**
         * Fetches the JSON representation of a bitstream created by
         * {@link createBitstream}.
         *
         * @param bitstreamURI
         */
        const fetchRepresentation = function (bitstreamURI) {
            $.ajax({
                method: "GET",
                url: bitstreamURI,
                success: function (data, status, xhr) {
                    uploadData(bitstreamURI, data.presigned_upload_url);
                },
                error: function (data, status, xhr) {
                    self.delete(bitstreamURI);
                    onError(null, xhr);
                }
            });
        };

        /**
         * Uploads data to the presigned URL provided in the representation
         * fetched by {@link fetchRepresentation}.
         *
         * @param bitstreamURI
         * @param presignedURL
         */
        const uploadData = function (bitstreamURI, presignedURL) {
            const xhr = new XMLHttpRequest();
            if (onProgressChanged) {
                xhr.upload.addEventListener("progress", onProgressChanged);
            }
            xhr.open("PUT", presignedURL, true);
            xhr.send(file);

            xhr.onreadystatechange = function () {
                if (this.readyState === this.HEADERS_RECEIVED) {
                    if (xhr.status === 0 || (xhr.status >= 200 && xhr.status < 400)) {
                        onSuccess(bitstreamURI);
                    } else if (onError) {
                        self.delete(bitstreamURI);
                        onError(null, xhr);
                    }
                }
            };
        }

        if (file.size > parseInt($("[name=max_upload_size]").val())) {
            onError("The file \"" + file.name + "\" exceeds the maximum " +
                "file size of 5 GB. Please contact us to make other arrangements.");
        } else {
            createBitstream();
        }
    };

};