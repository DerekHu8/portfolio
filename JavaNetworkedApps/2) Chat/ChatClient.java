/*
 * Jiali W. Derek H.
 * Creates a client that allows clients to communicate through a chatbox. 
 * Messages are seen by all clients and a friendlist is displayed.
 */

import java.io.*;
import java.net.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

public class ChatClient extends JFrame {
	
	private JTextArea incoming;			
	private JTextField outgoing;		
	private String name;		
	private DefaultListModel<String> friendModel;
	private String secretKey;			
	
	private Scanner reader;				
	private PrintWriter writer;	
	private Socket sock;		

	private final String SERVER_IP = "10.104.13.75";
	private final int SERVER_PORT = 4242;

	public ChatClient() {

		setLayout(null);
		setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
		setSize(900, 525);

		incoming = new JTextArea(15, 50);
		incoming.setLineWrap(true);
		incoming.setWrapStyleWord(true);
		incoming.setEditable(false);

		JScrollPane qScroller = new JScrollPane(incoming);
		qScroller.setVerticalScrollBarPolicy(ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS);
		qScroller.setHorizontalScrollBarPolicy(ScrollPaneConstants.HORIZONTAL_SCROLLBAR_ALWAYS);
		qScroller.setBounds(65,30,500,250);
		qScroller.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEtchedBorder(),"Chat"));
		qScroller.setOpaque(false);
		add(qScroller);

		JLabel outMessage = new JLabel("Message: ");
		outMessage.setFont(new Font("Times New Roman",Font.PLAIN,14));
		outMessage.setBounds(65,300,70,25);
		add(outMessage);

		outgoing = new JTextField(20);
		outgoing.setBounds(130,300,360,20);
		outgoing.addActionListener(new SendButtonListener());
		add(outgoing);

		friendModel = new DefaultListModel<String>();
		JList<String> friendList = new JList<String>(friendModel);
		JScrollPane friendScroll = new JScrollPane(friendList);
		friendList.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEtchedBorder(),"Friends"));
		friendScroll.setBounds(675,30,150,250);
		add(friendScroll);

		JButton sendButton = new JButton("Send");
		sendButton.addActionListener(new SendButtonListener());
		sendButton.setBounds(500,300,65,18);
		add(sendButton);

		JButton logOff = new JButton("Log Off");
		logOff.addActionListener(new LogOffButtonListener());
		logOff.setBounds(775,440,80,18);
		add(logOff);
		Random r = new Random();
		this.getContentPane().setBackground(new Color(r.nextInt(256),r.nextInt(256),r.nextInt(256)));

		setUpNetworking();

		Thread clientThread = new Thread(new IncomingReader());
		clientThread.start();
		
		setVisible(true);
		
	}

	//sets up the socket to read for the server and PrintWriter.
	private void setUpNetworking() {

		Scanner keyboard = new Scanner(System.in);
		System.out.print("Enter your name: ");
		name = keyboard.nextLine();

		setTitle("Chat Client - " +name);

		//Set up all instance variable
		try {
			sock = new Socket(SERVER_IP, SERVER_PORT);
			reader = new Scanner(sock.getInputStream());
			writer = new PrintWriter(sock.getOutputStream());
			secretKey = reader.nextLine();
		} 
		catch (IOException e) {
			e.printStackTrace();
		}
		
	}
	
	//Send button, sends message to server
	public class SendButtonListener implements ActionListener {

		//this method extracts the text from the textField and sends it to the server.
		public void actionPerformed(ActionEvent ev) {

			writer.println(name + ": " + outgoing.getText());
			writer.flush();

			// clears out the text and resets the cursor
			outgoing.setText("");
			outgoing.requestFocus();
			
		}
		
	}

	//Log Off button, closes socket
	public class LogOffButtonListener implements ActionListener{

		public void actionPerformed(ActionEvent ev){

			try{
				writer.println(name+":logoff:"+secretKey);
				writer.flush();
				
				sock.close();				

			}catch(IOException e){
				e.printStackTrace();
			}

			System.exit(0);
			
		}
		
	}
	
	//Reads in messages and places them in the text area
	class IncomingReader implements Runnable {
		public void run() {
			//Read in message from other clients sent from the server
			while(reader.hasNextLine()) {
				
				String receivedLine = reader.nextLine();
				String newFriend = receivedLine.substring(0, receivedLine.indexOf(":"));
				//Remove friends when they log off
				if(receivedLine.indexOf("logoff:"+secretKey) != -1) 
					friendModel.removeElement(newFriend);
				else {
					
					//Update text area
					synchronized(incoming) {
						incoming.append(receivedLine + "\n");
					}

					//Update friends
					if(!name.equals(newFriend) && !friendModel.contains(newFriend))
						friendModel.addElement(newFriend);
					
				}
				
			}
		}
	}

	public static void main(String[] args) {
		new ChatClient();
	}
}