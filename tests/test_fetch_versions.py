import json
import pytest
import responses
from scripts.fetch_dspace_versions import get_dspace_versions

@pytest.fixture
def mock_github_api():
    with responses.RequestsMock() as rsps:
        yield rsps

def test_fetch_angular_versions(mock_github_api, capsys):
    # Mock response for Angular versions
    mock_github_api.add(
        responses.GET,
        'https://api.github.com/repos/DSpace/dspace-angular/releases',
        json=[
            {'tag_name': 'dspace-7.6.3'},
            {'tag_name': 'dspace-8.1'},
            {'tag_name': 'dspace-9.0-rc1'}
        ],
        status=200
    )

    get_dspace_versions('angular')
    captured = capsys.readouterr()
    result = json.loads(captured.out)
    
    assert '7' in result
    assert '8' in result
    assert '9' in result
    assert '7.6.3' in result['7']
    assert '8.1' in result['8']
    assert '9.0-rc1' in result['9']

def test_fetch_backend_versions(mock_github_api, capsys):
    # Mock response for Backend versions
    mock_github_api.add(
        responses.GET,
        'https://api.github.com/repos/DSpace/DSpace/releases',
        json=[
            {'tag_name': 'dspace-7.6.3'},
            {'tag_name': 'dspace-8.1'},
            {'tag_name': 'dspace-9.0-rc1'}
        ],
        status=200
    )

    get_dspace_versions('backend')
    captured = capsys.readouterr()
    result = json.loads(captured.out)
    
    assert '7' in result
    assert '8' in result
    assert '9' in result
    assert '7.6.3' in result['7']
    assert '8.1' in result['8']
    assert '9.0-rc1' in result['9']

def test_version_sorting(mock_github_api, capsys):
    # Test version sorting with mixed order
    mock_github_api.add(
        responses.GET,
        'https://api.github.com/repos/DSpace/DSpace/releases',
        json=[
            {'tag_name': 'dspace-7.6.3'},
            {'tag_name': 'dspace-7.6.0'},
            {'tag_name': 'dspace-7.6.1'},
            {'tag_name': 'dspace-8.1'},
            {'tag_name': 'dspace-8.0'},
            {'tag_name': 'dspace-9.0-rc2'},
            {'tag_name': 'dspace-9.0-rc1'}
        ],
        status=200
    )

    get_dspace_versions('backend')
    captured = capsys.readouterr()
    result = json.loads(captured.out)
    
    # Check version sorting within groups
    assert result['7'] == ['7.6.0', '7.6.1', '7.6.3']
    assert result['8'] == ['8.0', '8.1']
    assert result['9'] == ['9.0-rc1', '9.0-rc2']

def test_api_error_handling(mock_github_api, capsys):
    # Test error handling for API failures
    mock_github_api.add(
        responses.GET,
        'https://api.github.com/repos/DSpace/DSpace/releases',
        status=404
    )

    with pytest.raises(SystemExit) as exc_info:
        get_dspace_versions('backend')
    
    assert exc_info.value.code == 1
    captured = capsys.readouterr()
    assert 'Error fetching releases: 404' in captured.err