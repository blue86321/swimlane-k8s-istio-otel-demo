package com.swimlanek8sistiodemo.service;

import com.swimlanek8sistiodemo.proto.service.GetPriceRequest;
import com.swimlanek8sistiodemo.proto.service.GetPriceResponse;
import com.swimlanek8sistiodemo.proto.service.PricingServiceGrpc;
import io.grpc.stub.StreamObserver;

/**
 * Implement gRPC method
 */
public class PricingService extends PricingServiceGrpc.PricingServiceImplBase {
    private final String swimlane;

    public PricingService(String swimlane) {
        this.swimlane = swimlane;
    }

    @Override
    public void getPrice(GetPriceRequest request, StreamObserver<GetPriceResponse> responseObserver) {
        GetPriceResponse response = GetPriceResponse.newBuilder()
            .setPrice(100)
            .setSwimlane(swimlane)
            .build();
        responseObserver.onNext(response);
        responseObserver.onCompleted();
    }
}
