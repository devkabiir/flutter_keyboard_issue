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
        onPressed: () => rowContainer.currentState.setState(
              () => rowContainer.currentState.children.add(RowItem(
                  key: ValueKey('LineItemWidget<1>'),
                  parent: rowContainer.currentState)),
            ),
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
  final List<Widget> children = [];
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      children: children,
      onReorder: (oldIdx, newIdx) {
        // Moved down
        if (oldIdx < newIdx) {
          // removing the item at oldIndex will shorten the list by 1.
          newIdx -= 1;
        }

        final row = rows.removeAt(oldIdx);
        final child = children.removeAt(oldIdx);
        row.index = newIdx;

        rows.insert(newIdx, row);
        children.insert(newIdx, child);
      },
    );
  }
}

class RowItem extends StatefulWidget {
  RowItem({ValueKey key, this.parent}) : super(key: key);
  final _RowContainerState parent;
  @override
  _RowItemState createState() => _RowItemState();
}

class _RowItemState extends State<RowItem> {
  Cell qtyWidget;
  Cell unitWidget;
  Cell priceWidget;
  Cell totalWidget;
  Widget nameField;

  /// Index of this row
  int index;
  @override
  void initState() {
    super.initState();
    index = widget.parent.rows.length;
    widget.parent.rows.add(this);
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
      controller: TextEditingController(text: 'line item...$index'),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('built row $index');
    return Dismissible(
      key: ValueKey('DismissibleRowItem<$index>'),
      background: Container(
        color: Colors.red,
        child: Icon(Icons.close),
      ),
      onDismissed: (direction) {
        widget.parent.rows.remove(this);
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
                    child: Icon(
                      Icons.drag_handle,
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
  Cell({this.controller, this.focusNode, this.name, this.parent});
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
              '\$CellTextField(${widget.name})<${widget.parent.index}>'),
          autofocus: false,
          autocorrect: false,
          dragStartBehavior: DragStartBehavior.down,
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
