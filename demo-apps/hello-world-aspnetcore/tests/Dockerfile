ARG BUILD_IMAGE
FROM ${BUILD_IMAGE} AS output

FROM mcr.microsoft.com/dotnet/core/sdk:3.1
LABEL build="temp"
WORKDIR /app

COPY --from=output /app .

COPY tests tests
WORKDIR /app/tests
RUN dotnet restore
# RUN dotnet test -r results --logger "html;LogFileName=results.html" --no-restore
# RUN dotnet test -r results --logger "trx;LogFileName=results.trx" --no-restore
RUN dotnet test -r results --logger "console;verbosity=detailed" --no-restore