FROM node:12-slim

WORKDIR /js

RUN npm install -g webpack webpack-cli

COPY ./package.json /js
COPY ./package-lock.json /js

RUN npm install .

COPY . /js

RUN webpack\
    --verbose\
    --display=verbose\
    --info-verbosity=verbose\
    --display-exclude\
    --display-modules\
    --display-max-modules\
    --display-chunks\
    --display-entrypoints\
    --display-origins\
    --display-cached\
    --display-cached-assets\
    --display-reasons\
    --display-depth\
    --display-used-exports\
    --display-provided-exports\
    --display-optimization-bailout\
    --display-error-details 
