

module SqlStruct.BookDetail;

import hunt.entity;

import SqlStruct.Book;


@Table("BookDetail")
class BookDetail {
    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    long id;

    long numberOfPages;

    @OneToOne("detail",FetchType.LAZY)
    Book book;
}