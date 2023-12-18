import os
from concurrent import futures

import grpc
from proto.health_check_pb2 import HealthCheckRequest, HealthCheckResponse
from proto.service_pb2 import (GetGoodsRequest, GetGoodsResponse,
                               GetPriceRequest, GetPriceResponse)

from proto import health_check_pb2_grpc, service_pb2_grpc

GOODS_LIST = [{"id": "1", "name": "Item 1"}, {"id": "2", "name": "Item 2"}]


class Health(health_check_pb2_grpc.HealthServicer):
    """Pod probe in K8s
    """
    def Check(self, request: HealthCheckRequest, context: grpc.ServicerContext) -> HealthCheckResponse:
        return HealthCheckResponse(
            status=HealthCheckResponse.ServingStatus.SERVING
        )

class GoodsService(service_pb2_grpc.GoodsServiceServicer):
    """Implement gRPC method
    """

    def __init__(self, swimlane: str):
        self.swimlane = swimlane

    def GetGoods(self, request: GetGoodsRequest, context: grpc.ServicerContext) -> GetGoodsResponse:
        # Iterate to get goods price
        goods_info_list = []
        for goods in GOODS_LIST:
            get_price_resp: GetPriceResponse = self._get_price_by_rpc(goods_id=goods.get('id'))
            goods_info_list.append(GetGoodsResponse.GoodsInfo(
                goods_id=goods.get('id'),
                goods_name=goods.get('name'),
                price=get_price_resp.price,
            ))

        return GetGoodsResponse(
            goods_info_list=goods_info_list,
            goods_swimlane=self.swimlane,
            pricing_swimlane=get_price_resp.swimlane,
        )

    @staticmethod
    def _get_price_by_rpc(goods_id: str) -> GetPriceResponse:
        """Get goods price by a gRPC call

        Args:
            goods_id (str): goods id
        """
        with grpc.insecure_channel(os.getenv("PRICING_SERVICE")) as channel:
            pricing_stub = service_pb2_grpc.PricingServiceStub(channel)
            response = pricing_stub.GetPrice(GetPriceRequest(goods_id=goods_id))
            return response


def serve():
    pricing_service = os.getenv("PRICING_SERVICE")
    if not pricing_service:
        raise ValueError("Error: PRICING_SERVICE is required in env.")

    swimlane = os.getenv("SWIMLANE")
    if not swimlane:
        raise ValueError("Error: SWIMLANE is required in env.")

    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    service_pb2_grpc.add_GoodsServiceServicer_to_server(GoodsService(swimlane), server)
    health_check_pb2_grpc.add_HealthServicer_to_server(Health(), server)

    server.add_insecure_port("[::]:50051")
    print("gRPC server (GoodsService) is running on port 50051")
    server.start()
    server.wait_for_termination()


if __name__ == '__main__':
    serve()
