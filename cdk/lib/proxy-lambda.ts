import { Construct } from "constructs";
import { NodejsFunction } from "aws-cdk-lib/aws-lambda-nodejs";
import { LambdaIntegration, RestApi } from "aws-cdk-lib/aws-apigateway";

export class PoxyLambda extends Construct {
  constructor(scope: Construct, id: string) {
    super(scope, id);
    const helloFunction = new NodejsFunction(this, "function");

    // new LambdaRestApi(this, "apigw", {
    //   handler: helloFunction,
    // });

    const api = new RestApi(this, "apigw");
    const idResource = api.root.addResource("id");
    const idParam = idResource.addResource("{id}");
    idParam.addMethod("GET", new LambdaIntegration(helloFunction));
  }
}
