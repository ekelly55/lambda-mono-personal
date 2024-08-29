# build
FROM node:20 AS build

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install



COPY src ./src

COPY tsconfig.json ./


RUN npm run build > build-log.txt || cat build-log.txt

# runtime

FROM public.ecr.aws/lambda/nodejs:20

WORKDIR ${LAMBDA_TASK_ROOT}

COPY --from=build /app/dist ${LAMBDA_TASK_ROOT}
COPY package.json ${LAMBDA_TASK_ROOT}

RUN npm install --production

CMD [ "index.handler" ]