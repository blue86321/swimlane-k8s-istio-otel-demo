package com.swimlanek8sistiodemo.service;

import com.swimlanek8sistiodemo.proto.healthcheck.HealthCheckRequest;
import com.swimlanek8sistiodemo.proto.healthcheck.HealthCheckResponse;
import com.swimlanek8sistiodemo.proto.healthcheck.HealthGrpc;
import io.grpc.stub.StreamObserver;

/**
 * Pod probe in K8s
 */
public class Health extends HealthGrpc.HealthImplBase {
    @Override
    public void check(HealthCheckRequest request, StreamObserver<HealthCheckResponse> responseObserver) {
        HealthCheckResponse response = HealthCheckResponse.newBuilder()
            .setStatus(HealthCheckResponse.ServingStatus.SERVING)
            .build();
        responseObserver.onNext(response);
        responseObserver.onCompleted();
    }
}
