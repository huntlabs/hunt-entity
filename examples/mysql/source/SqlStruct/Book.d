

module SqlStruct.Book;

import hunt.entity;

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