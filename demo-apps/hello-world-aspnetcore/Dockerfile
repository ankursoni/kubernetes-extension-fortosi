FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS build
LABEL build="temp"
WORKDIR /source

COPY *.csproj ./
RUN dotnet restore

COPY . .
RUN dotnet publish -c release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/core/aspnet:3.1
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT [ "dotnet", "hello-world.dll" ]