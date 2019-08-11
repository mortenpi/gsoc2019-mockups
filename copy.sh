#!/bin/bash
SRC_VERSION=v11
VERSION=v13

cp -R bulma/${SRC_VERSION} bulma/${VERSION}
rm -R bulma/${VERSION}/documenter
rm -R bulma/${VERSION}/julia


cp -R ~/Julia/JuliaDocs/Documenter.bulma/docs/build/ bulma/${VERSION}/documenter
cp bulma/${SRC_VERSION}/documenter/siteinfo.js bulma/${VERSION}/documenter/

cp -R ~/Julia/julia-bulma/doc/_build/html/en/ bulma/${VERSION}/julia
cp bulma/${SRC_VERSION}/julia/siteinfo.js bulma/${VERSION}/julia/
