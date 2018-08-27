

module SqlStruct.BookDetail;

import hunt.entity;

import SqlStruct.Book;


@Table("BookDetail")
class BookDetail {
    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    long id;

    long numberOfPages;

    @OneToOne(FetchType.LAZY, "detail")
    Book book;
}