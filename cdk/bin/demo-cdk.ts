#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { DemoCdkStack } from '../lib/demo-cdk-stack';

const app = new cdk.App();
new DemoCdkStack(app, 'DemoCdkStack');
