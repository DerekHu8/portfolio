/* Name: Derek Chang
About: uses a circular linked list as a queue where it is first in and first out where the user is able to use the queue by adding, removing. looking for emptiness, and looking at first element */

import java.util.*;

public class CircularQueue<E> {
	
	private ListNode end;
	
	// checks to see if the list is empty
	public boolean isEmpty()
	{
		return end == null;
	}
	
	// adds an element to the list if valid
	public void add(E item)
	{
		ListNode newNode = new ListNode(item, null);
		
		// creates the first element if there are no elements
		if (end == null)
		{
			end = newNode;
			end.next = end;
		}
		// creates an element for the end
		else
		{
			newNode.next = end.next;
			end.next = newNode;
			end = newNode;
		}
	}
	
	// looks at the front of the list if possible
	public E peek()
	{
		// checks to see if the list is empty
		if (end == null)
		{
			throw new NoSuchElementException("Queue is empty");
		}
		
		return end.next.data;
	}
	
	// gets rid of the front element of the list
	public E remove()
	{
		// checks to see if the list is empty
		if (end == null)
		{
			throw new NoSuchElementException("Queue is empty");
		}
		
		ListNode front = end.next;
		E dataRemoved = front.data;
		
		// removes the only element in the list if there is one element
		if (front == end)
		{
			end = null;
		}
		// removes the first element of the list
		else
		{
			end.next = front.next;
		}
		
		front.next = null;
		
		return dataRemoved;
	}
	
	public class ListNode {
		
		private E data;
		private ListNode next;
		
		public ListNode(E d, ListNode n)
		{
			data = d;
			next = n;
		}
	}
}