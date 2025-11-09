export async function handler(event) {
  console.log("Received event:", JSON.stringify(event));

  // hello from local lol
  const id = event.pathParameters ? event.pathParameters.id : null;

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: `You requested ID: ${id}`,
    }),
  };
}
