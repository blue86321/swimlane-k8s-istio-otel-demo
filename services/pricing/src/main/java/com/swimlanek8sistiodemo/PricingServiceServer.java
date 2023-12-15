package com.swimlanek8sistiodemo;

import com.swimlanek8sistiodemo.service.PricingService;
import io.grpc.*;

import java.io.IOException;

public class PricingServiceServer {

    public static void main(String[] args) throws IOException, InterruptedException {
        String swimlane = System.getenv("SWIMLANE");
        if (swimlane == null || swimlane.isEmpty()) {
            System.err.println("Error: SWIMLANE is required in env.");
            System.exit(1);
        }

        int port = 50052;
        Server server = Grpc.newServerBuilderForPort(port, InsecureServerCredentials.create())
            .addService(ServerInterceptors.intercept(new PricingService(swimlane), new HeaderInterceptor()))
            .build()
            .start();
        System.out.println("gRPC server (PricingService) is running on port " + port);
        server.awaitTermination();
    }

    /**
     * Intercept gRPC request and log data for debugging
     */
    private static class HeaderInterceptor implements ServerInterceptor {
        @Override
        public <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(ServerCall<ReqT, RespT> call, Metadata headers,
                                                                     ServerCallHandler<ReqT, RespT> next) {
            // Access headers here if needed
            String baggage = headers.get(Metadata.Key.of("baggage", Metadata.ASCII_STRING_MARSHALLER));
            System.out.println("Received baggage header in interceptor: " + baggage);

            return next.startCall(call, headers);
        }
    }
}
