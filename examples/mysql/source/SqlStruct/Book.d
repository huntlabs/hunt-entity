

module SqlStruct.Book;

import entity;

import SqlStruct.BookDetail;


@Table("Book")
class Book {
    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    long id;

    string name;
    
    @OneToOne()
    @JoinColumn("book_detail")
    BookDetail detail;


}