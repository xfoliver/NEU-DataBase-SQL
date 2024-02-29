import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public class CalculateBalance {
    public static void main(String[] args) {
        // file path
        String filePath = "loan.csv";

        // initialize each number
        double marriedTotal = 0.0;
        int marriedCount = 0;
        double singleTotal = 0.0;
        int singleCount = 0;
        double divorcedTotal = 0.0;
        int divorcedCount = 0;

        try (BufferedReader reader = new BufferedReader(new FileReader(filePath))) {
            String line;
            //skip the first line of headings,like age, name, etc
            reader.readLine();
            while ((line = reader.readLine()) != null) {
                // extract marital and balance information from the customer list.
                String[] columns = line.split(",");

                if (columns.length >= 0) {
                    String maritalStatus = columns[2].trim(); // the third column is marital status
                    double balance = Double.parseDouble(columns[5].trim()); // the sixth column is balance

                    // according marital status to update balance
                    if ("married".equals(maritalStatus)) {
                        marriedTotal += balance;
                        marriedCount++;
                    } else if ("single".equals(maritalStatus)) {
                        singleTotal += balance;
                        singleCount++;
                    } else if ("divorced".equals(maritalStatus)) {
                        divorcedTotal += balance;
                        divorcedCount++;
                    }
                }
            }

            // calculate each marital status average balance and print out
            if (marriedCount > 0) {
                double marriedAverage = marriedTotal / marriedCount;
                System.out.println("Average balance for married customers: " + marriedAverage);
            }
            if (singleCount > 0) {
                double singleAverage = singleTotal / singleCount;
                System.out.println("Average balance for single customers: " + singleAverage);
            }
            if (divorcedCount > 0) {
                double divorcedAverage = divorcedTotal / divorcedCount;
                System.out.println("Average balance for divorced customers: " + divorcedAverage);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

