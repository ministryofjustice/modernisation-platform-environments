package example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;
import java.util.Map;

public class HelloWorldHandler implements RequestHandler<Map<String, Object>, String> {
    @Override
    public String handleRequest(Map<String, Object> event, Context context) {
        String secretName = System.getenv("SECRET_NAME");
        String regionEnv = System.getenv("AWS_REGION");
        Region region = Region.of(regionEnv);

        try (SecretsManagerClient client = SecretsManagerClient.builder()
                .region(region)
                .build()) {

            GetSecretValueRequest request = GetSecretValueRequest.builder()
                    .secretId(secretName)
                    .build();

            GetSecretValueResponse response = client.getSecretValue(request);

            String secret = response.secretString();

            if (secret != null && !secret.isEmpty()) {
                System.out.println("Hello World ✅ Secret found");
                return "Hello World";
            } else {
                System.out.println("Secret is empty");
                return "Secret is empty";
            }

        } catch (Exception e) {
            System.out.println("Error reading secret: " + e.getMessage());
            return "Error reading secret";
        }

    }
}
