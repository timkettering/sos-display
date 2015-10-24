let React = require('react');

let Panel = require('react-bootstrap').Panel;
let ListGroup = require('react-bootstrap').ListGroup;
let ListGroupItem = require('react-bootstrap').ListGroupItem;
let ButtonGroup = require('react-bootstrap').ButtonGroup;
let Button = require('react-bootstrap').Button;
let DropdownButton = require('react-bootstrap').DropdownButton;
let MenuItem = require('react-bootstrap').MenuItem;

let actions = require('../actions');

module.exports = React.createClass({
    render: function() {
        let current = this.props.data.current;
        let modeListing = this.props.data.list.map(function(mode) {
            return (
                <MenuItem key={mode.id} onClick={actions.setMode.bind(this, current, mode)}>
                  {mode.title}
                </MenuItem>
            );
        });
        return (
            <Panel header="Mode Controls">
              <DropdownButton title="Select Mode" id="select-mode">
                {modeListing}
              </DropdownButton>
              <h4>
                Currently showing <strong>{current.title}</strong>.
              </h4>
              <ButtonGroup vertical>
                <Button onClick={actions.resetMode.bind(this)}>
                  Reset Mode
                </Button>
                <Button>
                  Toggle Kinect Off
                </Button>
                <Button>
                  Disable Random Jumps
                </Button>
              </ButtonGroup>
          </Panel>
        );
    }
});
