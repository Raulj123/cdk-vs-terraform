import { Stack, StackProps } from "aws-cdk-lib";
import { Construct } from "constructs";
import { PoxyLambda } from "./proxy-lambda";

export class DemoCdkStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);
    new PoxyLambda(this, "proxy-lambda");
  }
}
