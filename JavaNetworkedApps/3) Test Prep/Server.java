/*
 * Derek Hu
 * Period 4
 * This is the server side that allows for an unlimited number of clients to connect and 
 * take the test prep. The server records the high score and reports it when each client
 * finishes their test.
 */

import java.io.*;
import java.net.*;
import java.util.*;

public class Server {
	
	private AllQuestions questions;
	private String lead;
	private int max;
	private int totalMax;

	public Server(){
		//gets questions
		questions = new AllQuestions("questions.txt");
		
		try {
			ServerSocket server = new ServerSocket(4242);
			
			//infinitely accepts and initializes
			while (true) {
				Socket theSock = server.accept();
				ClientHandler threadJob = new ClientHandler(theSock);
				Thread newThread = new Thread(threadJob);
				newThread.start();
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	//handles the client, giving each a thread to run test
	private class ClientHandler implements Runnable{

		private Scanner in;
		private PrintWriter out;
		private String name;
		
		public ClientHandler(Socket s){
			try {
				in = new Scanner(s.getInputStream());
				out = new PrintWriter(s.getOutputStream());
				
				//gets name and sends num of questions
				name = in.nextLine();
				out.println(questions.size() + "");
				out.flush();
			} catch (IOException e) {
				e.printStackTrace();
				System.exit(2);
			}
		}
		
		//runs test prep interface for a client
		public void run(){
			int score = 0;
			
			//sends all the questions
			for (int i = 0; i < questions.size(); i++) {
				Question curQuestion = questions.get(i);
				
				//send actual question
				out.println(curQuestion.actualQuestion);
				out.flush();
				
				//send choices
				for (int j = 0; j < curQuestion.possibleAnswers.size(); j++) {
					out.println(curQuestion.possibleAnswers.get(j));
					out.flush();
				}
				
				//gets answer
				int answer = Integer.parseInt(in.nextLine());
				
				//determines right or wrong
				if (answer == curQuestion.correctAnswer) {
					out.println("Correct!");
					score++;
				}
				else 
					out.println("Wrong!");
				
				out.flush();
			}
			
			//determines who has the highest score
			if (score > max) {
				synchronized(lead) {
					max = score;
					totalMax = 1;
					lead = name;
				}
			}
			else if (score == max) {
				synchronized(lead) {
					totalMax++;
				}
			}
			
			//sends final high score message
			if (totalMax == 1) 
				out.println(lead + " has the high score with " + max + " correct.");
			else 
				out.println(totalMax + " people have the high score of " + max + " correct.");
			
			out.flush();
		
			//close all connections when finished
			in.close();
			out.close();
		}
	}

	//simulates a question, storing the question, choices, and correct answer
	public class Question {

		private String actualQuestion;
		private ArrayList<String> possibleAnswers;
		private int correctAnswer;  //[0,3]

		public Question(String actual, ArrayList<String> possible, int correct) {
			actualQuestion = actual;
			possibleAnswers = possible;
			correctAnswer = correct;
			shuffle();
		}

		//shuffles the answer choices
		private void shuffle() {
			int numTimes = (int)(Math.random() * 50);

			for(int i = 0; i < numTimes; i++) {
				int toMove = (int)(Math.random() * 3);

				//randomly move one of the first 3 elements to the end
				String moveIt = possibleAnswers.remove(toMove);
				possibleAnswers.add(moveIt);

				//correctAnswer IV needs to move along with the possibleAnswer
				if(toMove == correctAnswer)
					correctAnswer = 3;
				else if(toMove < correctAnswer)
					correctAnswer--;
			}
		}

		public boolean isCorrect(int guess) {
			return guess == correctAnswer;
		}
	}

	//simulates a list of questions
	public class AllQuestions extends ArrayList<Question> {

		public AllQuestions(String fname) {
			Scanner fileIn = null;

			try {

				fileIn = new Scanner(new File(fname));

			} catch(FileNotFoundException e) {

				System.exit(-1);
			}

			//gets needed information from the file
			while(fileIn.hasNextLine()) {
				String question = fileIn.nextLine();
				ArrayList<String> answers = new ArrayList<String>();

				for (int i = 0; i < 4; i++) {
					answers.add(fileIn.nextLine());
				}

				int correct = fileIn.nextInt();
				fileIn.nextLine();

				//adds question to ArrayList
				add(new Question(question, answers, correct));
			}			
			shuffleQuestions();
		}

		//mixes up the question order
		private void shuffleQuestions() {
			//runs random times 0-50
			int numTimes = (int)(Math.random() * 51);

			//gets random question and moves to back
			for (int i = 0; i < numTimes; i++) {
				int toMove = (int)(Math.random() * size());

				Question moveIt = remove(toMove);
				add(moveIt);
			}
		}
	}

	//starts the server
	public static void main(String[] args){
		new Server();
	}
}