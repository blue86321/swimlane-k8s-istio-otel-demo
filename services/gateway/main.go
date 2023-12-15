package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	pb "github.com/blue86321/swimlane-k8s-istio-demo/proto"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

func getGoods(swimlane string) (*pb.GetGoodsResponse, error) {

	// Set up a connection to the server.
	conn, err := grpc.Dial(os.Getenv("GOODS_SERVICE"), grpc.WithInsecure())
	if err != nil {
		return nil, fmt.Errorf("could not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewGoodsServiceClient(conn)

	// Propagate `x-swimlane` to outbound servers
	md := metadata.Pairs("baggage", "x-swimlane="+swimlane)
	ctx := metadata.NewOutgoingContext(context.Background(), md)
	r, err := c.GetGoods(ctx, &pb.GetGoodsRequest{})
	if err != nil {
		return nil, fmt.Errorf("could not get goods: %v", err)
	}
	return r, nil
}

func main() {
	if os.Getenv("GOODS_SERVICE") == "" {
		log.Fatal("Error: GOODS_SERVICE is required in env.")
	}

	// Endpoint config
	// 1. Home
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "Hello, world! Try endpoint /goods")
	})
	// 2. Goods (chain multiples microservices)
	http.HandleFunc("/goods", func(w http.ResponseWriter, r *http.Request) {
		swimlane := r.Header.Get("x-swimlane")

		goodsResponse, err := getGoods(swimlane)
		if err != nil {
			log.Printf("Error getting goods: %v", err)
			http.Error(w, "Error getting goods", http.StatusInternalServerError)
			return
		}

		fmt.Fprint(w, "Goods Swimlane: ", goodsResponse.GoodsSwimlane, "\n")
		fmt.Fprint(w, "Pricing Swimlane: ", goodsResponse.PricingSwimlane, "\n")
		for _, goodsInfo := range goodsResponse.GoodsInfoList {
			fmt.Fprintf(w, "GoodsID: %s, GoodsName: %s, Price: %d\n", goodsInfo.GoodsId, goodsInfo.GoodsName, goodsInfo.Price)
		}
	})

	// Start the server on port 8080
	fmt.Println("Http server (Gateway) is running on port 8080")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		fmt.Println("Error:", err)
	}
}
