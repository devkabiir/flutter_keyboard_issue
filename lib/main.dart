import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keyboard issue',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Keyboard issue'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final rowContainer = GlobalKey<_RowContainerState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            MultiLineTextField(),
            Flexible(child: RowContainer(rowContainer)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => rowContainer.currentState.addRow(),
        tooltip: 'Add',
        child: Icon(Icons.add),
      ),
    );
  }
}

class MultiLineTextField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            style: Theme.of(context).textTheme.body2,
            maxLines: null,
            enableInteractiveSelection: true,
            controller: TextEditingController(text: 'Multi line text'),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.multiline,
          ),
        ),
      ),
    );
  }
}

class RowContainer extends StatefulWidget {
  RowContainer(Key key) : super(key: key);
  @override
  _RowContainerState createState() => _RowContainerState();
}

class _RowContainerState extends State<RowContainer> {
  final List<_RowItemState> rows = [];
  final List<RowItem> children = [];

  void addRow() => setState(() => children.add(RowItem(
      originalIndex: children.length,
      parent: this,
      uid: DateTime.now().microsecondsSinceEpoch)));

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      children: children,
      onReorder: (oldIdx, newIdx) {
        // These two lines are workarounds for ReorderableListView problems
        if (newIdx > children.length) newIdx = children.length;
        if (oldIdx < newIdx) newIdx--;

        final row = rows.removeAt(oldIdx);
        rows.insert(newIdx, row);

        /// Now that we have all states in proper order, updating their indices
        for (var i = 0; i < rows.length; i++) {
          rows[i].setState(() => rows[i].index = i);
          // rows[i].index = i;
        }

        // See: https://github.com/flutter/flutter/issues/21829
        Future.delayed(Duration(milliseconds: 20), () {
          setState(() {
            final child = children.removeAt(oldIdx);
            children.insert(newIdx, child);
          });
        });
      },
    );
  }
}

class RowItem extends StatefulWidget {
  RowItem({this.originalIndex, this.parent, this.uid})
      : super(key: ValueKey('RowItem<$uid>'));
  final _RowContainerState parent;
  final int originalIndex;

  /// Every row has a unique id besides it's index because after drag'N'drop or
  /// deleting a row or adding a row or combination of these three actions,
  /// Another row may end up with the same index. But at any given
  /// time all rows will have unique index and all of them will match what the user
  /// sees in the UI. This uid is used for creating the `Key` of this widget
  /// because we reuse the existing widgets. And we reuse the widgets because we
  /// need to maintain their states and thier childrens Like FocusNode and TextEdittingController
  final int uid;
  @override
  _RowItemState createState() => _RowItemState();
}

class _RowItemState extends State<RowItem> {
  Cell qtyWidget;
  Cell unitWidget;
  Cell priceWidget;
  Cell totalWidget;
  Widget nameField;

  /// Effective index of this row
  int index;

  @override
  void initState() {
    super.initState();

    /// Initially when the row is inserted this will be it's valid index
    index = widget.originalIndex;

    qtyWidget = Cell(
      controller: TextEditingController(),
      focusNode: FocusNode(),
      name: 'qty',
      parent: this,
    );
    unitWidget = Cell(
      controller: TextEditingController(),
      focusNode: FocusNode(),
      name: 'unit',
      parent: this,
    );
    priceWidget = Cell(
      controller: TextEditingController(),
      focusNode: FocusNode(),
      name: 'price',
      parent: this,
    );
    totalWidget = Cell(
      controller: TextEditingController(),
      focusNode: FocusNode(),
      name: 'total',
      parent: this,
    );

    nameField = TextField(
      maxLines: 1,
      enableInteractiveSelection: true,
      textInputAction: TextInputAction.next,
      controller: TextEditingController(),
      decoration: InputDecoration(hintText: 'originalIndex:$index'),
    );
    Future.delayed(Duration(milliseconds: 20),
        () => widget.parent.setState(() => widget.parent.rows.add(this)));
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('DismissibleRowItem(${widget.uid})<$index>'),
      background: Container(
        color: Colors.red,
        child: Icon(Icons.close),
      ),
      onDismissed: (direction) {
        widget.parent.setState(() {
          widget.parent.rows.remove(this);

          widget.parent.children.remove(widget);

          /// Update all the rows below this one
          for (int i = index; i < widget.parent.rows.length; i++) {
            widget.parent.rows[i].index = i;
          }
        });
      },
      direction: DismissDirection.endToStart,
      child: Card(
        child: Container(
          height: 128.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.drag_handle,
                        ),
                        Text('${index + 1}.')
                      ],
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4.0),
                      child: nameField,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  qtyWidget,
                  unitWidget,
                  priceWidget,
                  totalWidget,
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Cell extends StatefulWidget {
  Cell({this.controller, this.focusNode, this.name, this.parent})
      : super(key: ValueKey('Cell($name) of RowItem<${parent.widget.uid}>'));
  final TextEditingController controller;
  final FocusNode focusNode;
  final String name;
  final _RowItemState parent;
  @override
  _CellState createState() => _CellState();
}

class _CellState extends State<Cell> {
  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 2,
      fit: FlexFit.loose,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: TextField(
          key: ValueKey(
              'CellTextField(${widget.name}) of RowItem<${widget.parent.widget.uid}>'),
          autofocus: false,
          autocorrect: false,
          dragStartBehavior: DragStartBehavior.start,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          style: Theme.of(context).textTheme.subtitle,
          maxLines: 1,
          enableInteractiveSelection: true,
          textInputAction: TextInputAction.next,
          controller: widget.controller,
          decoration: InputDecoration(hintText: widget.name),
        ),
      ),
    );
  }
}
