#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
	int num = 0;
	int total = 0;
	int numGrades = 0;
	int max = 0;
	int min = 100;
	
	printf("Enter the grade: ");
	scanf("%d", &num);
	
	while (num != -1) {
		total += num;
		numGrades++;
		
		if (num > max) {
			max = num;
		}
		if (num < min) {
			min = num;
		}
		
		printf("Enter the grade: ");
		scanf("%d", &num);
	}
	
	if (numGrades == 0) {
		printf("No grades were entered.");
	}
	else {
		double percentage = (double)total / numGrades;
		
		printf("The number of grades entered was %d", numGrades);
		printf("\nThe average grade is %.2f \n", percentage);
		printf("The minimum grade was %d \n", min);
		printf("The maximum grade was %d \n", max);
	}
	
	return 0;
}
