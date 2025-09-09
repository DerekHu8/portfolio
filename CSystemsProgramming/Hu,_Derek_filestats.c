/*
Derek Hu and Jiali Wei
Period 4
This program continuously prompts the user for lines until they press Cntrl+D.
It then displays some stats about the lines they entered.

Monster Lyrics File Results: 
Number of Words: 165
Number of Lines: 26
Average Word Length: 3.98
Largest Word Length: 10
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
	
	int numWords =0;
	int numLines = 0;
	int totalWordLen = 0;
	int largestWord = 0;
	
	char* line = NULL;
	size_t len = 0;
	ssize_t read;
	
	printf("Continuously enter lines or press Cntrl+D to quit:\n");
	
	while ((read = getline(&line, &len, stdin)) != -1) {
		line[strlen(line)-1] = '\0';	
		
		char* splitter = strtok(line," ");
		while(splitter != NULL){

			numWords++;
			int curLen = strlen(splitter);
			totalWordLen += curLen;
			
			if (curLen > largestWord) {
				largestWord = curLen;
			}
			
			splitter = strtok(NULL," "); 
		}

		numLines++;		 
	}
	
	printf("Number of Words: %d\n", numWords);
	printf("Number of Lines: %d\n", numLines);
	printf("Average Word Length: %.2f\n", (double)totalWordLen / numWords);
	printf("Largest Word Length: %d\n", largestWord);
	
	return 0;
}
