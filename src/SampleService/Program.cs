using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Serilog;
using Serilog.Events;

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Information)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .CreateBootstrapLogger();

try
{
    Log.Information("Starting application");

    // configure builder
    var builder = WebApplication.CreateBuilder();

    // logging
    builder.Host
        .UseSerilog((context, services, configuration) =>
        {
            configuration
                .ReadFrom.Configuration(context.Configuration)
                .ReadFrom.Services(services);
        }, writeToProviders: true);
    Log.Information("Logging configured for application");

    // health checks
    builder.Services.AddHealthChecks();

    // content root
    builder.WebHost
        .UseContentRoot(Directory.GetCurrentDirectory());

    // configure web application
    var app = builder.Build();
    app.UseSerilogRequestLogging();

    app.Logger.LogInformation($"Environment name: {app.Environment.EnvironmentName}");

    if (app.Environment.IsDevelopment())
    {
        app.UseDeveloperExceptionPage();
    }

    app.UseHealthChecks("/health");

    app.UseRouting();
    app.MapGet("/", () =>
    {
        var next = Random.Shared.Next(0, 9);
        return Enumerable.Range(next, 5);
    });

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
    return 1;
}
finally
{
    Log.CloseAndFlush();
}

return 0;
