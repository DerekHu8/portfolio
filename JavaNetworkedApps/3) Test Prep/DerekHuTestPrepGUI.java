/*
 * Derek Hu
 * Period 4
 * This is the client side for running test prep. The client handles all of the GUI
 * and connects to the server to get the content and results of their test.
 */

import java.util.*;
import java.awt.*;
import javax.imageio.ImageIO;
import javax.swing.*;
import javax.swing.event.*;
import java.awt.event.*;
import java.awt.image.BufferedImage;
import java.io.*;
import java.net.Socket;

public class DerekHuTestPrepGUI extends JFrame implements ActionListener {
	
	private JLabel questionNum;
	private JTextArea qArea;
	private DefaultListModel<String> myModel;
	private JList<String> aArea;
	private JButton submit;
	private JLabel percentage;
	private int index;
	private int correct;
	private int size;
	
	private Scanner reader;				
	private PrintWriter writer;	
	private Socket sock;		
	
	private final String SERVER_IP = "10.104.13.75";
	private final int SERVER_PORT = 4242;
	
	public DerekHuTestPrepGUI() {
		setUpNetworking();
		
		//initializing pop-up
		setSize(500,850);
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		
		//setting background image
		PicPanel mainPanel = new PicPanel("totoro.jpg");
		mainPanel.setLayout(null);
		
		//header and question number
		questionNum = new JLabel();
		questionNum.setFont(new Font("Comic Sans",Font.PLAIN,24));
		questionNum.setBounds(160,33,200,50);
		
		//question box
		qArea = new JTextArea();
		qArea.setEditable(false);
		qArea.setLineWrap(true);
		qArea.setWrapStyleWord(true);
		qArea.setBorder(BorderFactory.createTitledBorder(BorderFactory.createLineBorder(Color.blue),"Questions"));
		qArea.setBounds(40,100,400,250);
		
		//puts choices into a model, JList, then JScrollPane
		myModel = new DefaultListModel<String>();
		
		aArea = new JList<String>(myModel);
		aArea.setSelectionMode(ListSelectionModel.SINGLE_SELECTION); 
		
		JScrollPane jscp = new JScrollPane(aArea); 
		jscp.setBorder(BorderFactory.createTitledBorder(BorderFactory.createLineBorder(Color.blue),"Answers"));
		jscp.setBounds(40,400,400,200);

		//submit button
		submit = new JButton("Submit");
		submit.setBounds(180,620,125,40);
		submit.addActionListener(this);
		
		//percent correct display
		percentage = new JLabel("Percentage Correct: 0.00");
		percentage.setFont(new Font("Comic Sans",Font.PLAIN,24));
		percentage.setBounds(120,650,400,100);
		
		//adds background image then everything on top
		add(mainPanel);
		mainPanel.add(questionNum);
		mainPanel.add(qArea);
		mainPanel.add(jscp);
		mainPanel.add(submit);
		mainPanel.add(percentage);
		
		//gets first question
		loadQuestion();
		
		setVisible(true);
	}
	
	//connects client to server
	private void setUpNetworking() {
		//gets client name
		Scanner input = new Scanner(System.in);
		System.out.print("Enter your name: ");
		String name = input.nextLine();

		setTitle("AP Prep - " + name);

		try {
			sock = new Socket(SERVER_IP, SERVER_PORT);
			reader = new Scanner(sock.getInputStream());
			writer = new PrintWriter(sock.getOutputStream());
			
			//sends name and gets num of questions
			writer.println(name);
			writer.flush();
			size = Integer.parseInt(reader.nextLine());
		} 
		catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	//submit button is pressed
	public void actionPerformed(ActionEvent ae) {
		int guess = aArea.getSelectedIndex();
		
		//no answer selected
		if (guess == -1) 
			return;
		
		//sends guess
		writer.println(guess);
		writer.flush();
		
		//gets if they were right or wrong
		String status = reader.nextLine();
		if (status.equals("Correct!")) {
			correct++;
			displayMessage("CORRECT!");
		}
		else 
			displayMessage("WRONG!");
		
		index++;
		
		//updates percentage
		percentage.setText("Percentage Correct: " + String.format("%.2f", (double) correct / index * 100));
		
		//loads next question if there are more questions
		if (index < size) 
			loadQuestion();
		else {
			//disables button and displays high score
			submit.setEnabled(false);
			String finalMessage = reader.nextLine();
			displayMessage(finalMessage);
			
			//closes
			try {
				sock.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}
	
	//gets next question from server and loads
	private void loadQuestion() {
		questionNum.setText("Question " + (index + 1) + " of " + size);
		qArea.setText(reader.nextLine());
		myModel.clear();
		
		//all choices
		for (int i = 0; i < 4; i++) {
			myModel.addElement(reader.nextLine());
		}
	}
	
	//pop-up with message
	private void displayMessage(String text) {
		JOptionPane.showMessageDialog(null, text);
	}
	
	//used to display pictures
	public class PicPanel extends JPanel {

		private BufferedImage image;
		
		public PicPanel(String fname) {

			//reads the image
			try {
				image = ImageIO.read(new File(fname));
				
			} catch (IOException ioe) {
				System.out.println("Could not read in the pic");
				System.exit(0);
			}
		}
		
		//this will draw the image
		public void paintComponent(Graphics g) {
			super.paintComponent(g);
			g.drawImage(image,0,0,this);
		}
	}
	
	public static void main(String[] args) {
		new DerekHuTestPrepGUI();
	}
}