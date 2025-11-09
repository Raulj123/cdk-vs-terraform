import { Context, APIGatewayProxyResult, APIGatewayEvent } from "aws-lambda";

export const handler = async (
  event: APIGatewayEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  const id = event.pathParameters?.id || null;
  console.log(`Event: ${JSON.stringify(event, null, 2)}`);
  console.log(`Event Param: ${id}`);
  console.log(`Context: ${JSON.stringify(context, null, 2)}`);
  const data = await getPost(id);
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: data,
    }),
  };
};

async function getPost(id: string | null) {
  if (!id) return "No id sent";
  const url = `https://jsonplaceholder.typicode.com/posts/${id}`;
  try {
    const resp = await fetch(url);
    if (!resp.ok) {
      throw new Error(`Failed to fetch post ${id}: ${resp.statusText}`);
    }
    const data = await resp.json();
    return data;
  } catch (err) {
    return err;
  }
}
