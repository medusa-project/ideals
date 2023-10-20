#!/bin/sh

rm -f log/test.log
bin/rails test
bin/rails zeitwerk:check
