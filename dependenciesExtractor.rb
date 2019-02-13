#Run methods with ruby -r "C:/Users/jpms2/Desktop/tg/dependenciesExtractor.rb" -e "DependenciesExtractor.new.find_all_relations 'C:/Users/jpms2/Desktop/tg/tracks/app/controllers/application_controller.rb,C:/Users/jpms2/Desktop/tg/tracks/lib/login_system.rb'"

require 'json'

class DependenciesExtractor

  def preprocess(target_project)
    Dir.chdir(target_project){
      `rubrowser > C:/Users/jpms2/Desktop/tg/TestInterfaceEvaluation/output.html`
    }
  end

  def process()
    extract('C:/Users/jpms2/Desktop/tg/TestInterfaceEvaluation/output.html')
    hashJ = JSON.parse(read_file('C:/Users/jpms2/Desktop/tg/TestInterfaceEvaluation/dependencies.json'))
    #hashJ = handle_missing_names(hashJ)
    write_file(hashJ.to_json, 'C:/Users/jpms2/Desktop/tg/TestInterfaceEvaluation/dependencies.json')
  end

  def extract(output_path)
    file_content = read_file(output_path)
    json_regex = /var data = (.*);/
    json_data = json_regex.match(file_content)[1]
    write_file(json_data, 'C:/Users/jpms2/Desktop/tg/TestInterfaceEvaluation/dependencies.json')
  end

  def find_all_relations(file_paths)
    response = ''
    file_path_arr = file_paths.split(",")
    file_path_arr.each do |file_path|
      dependency_def = find_definition(file_path, "file")
      if dependency_def != 'Not found'
        response += find_formated_relations(file_path)
      end
    end
    puts (response[0..-2]).split(',').uniq.join(",")
  end

  def find_formated_relations(file_path)
    relations = find_relations(file_path)
    response = ''
    if relations != 'Not found'
      relations_arr = relations[file_path.gsub(/\\/, '/')].uniq { |t| t['namespace'] }
      relations_arr.each do |relation|
        path = find_definition(relation['namespace'], "namespace")
        if path != 'Not found'
          response += path[relation['namespace'].downcase][0]['file'] + ','
        end
      end
    end
    #Return comes with extra ',' take care
    response
  end

  def find_relations(file_path)
    json = JSON.parse(read_file('C:/Users/jpms2/Desktop/tg/TestInterfaceEvaluation/dependencies.json'))
    dep = Hash.new
    json["relations"].each do |dependency|
      if dependency["file"].gsub(/\\|\//, '').downcase == file_path.gsub(/\\|\//, '').downcase
        dep["#{dependency["file"]}"] ? dep["#{dependency["file"]}"].push(dependency) : dep["#{dependency["file"]}"] = [dependency]
      end
    end
    dep.empty? ? 'Not found' : dep
  end

  def find_definition(search_param, attribute)
    json = JSON.parse(read_file('C:/Users/jpms2/Desktop/tg/TestInterfaceEvaluation/dependencies.json'))
    dep = Hash.new
    json["definitions"].each do |definition|
      if definition[attribute].gsub(/\\|\//, '').downcase == search_param.gsub(/\\|\//, '').downcase
        dep["#{definition[attribute]}"] ? dep["#{definition[attribute]}"].push(definition) : dep["#{definition[attribute]}".downcase] = [definition]
      end
    end
    dep.empty? ? 'Not found' : dep
  end
# TODO: Catch more names correctly 
  def find_missing_name(path, target_line)
    name_regex0 = /^([A-Z][^.]+)/
    name_regex1 = / +:*([A-Z][^(.|,| )]+)/
    name_regex2 = /\(([A-Z].*?)(\)|\.|\,)/
    name_regex3 = /(\{:*([A-Z].*?[^.]+?)\})/
    colon_regex = /::/
    lines = File.readlines(path)
    target_line_value = lines[target_line - 1]
    if(name_regex0.match?(target_line_value))
      prob_name = name_regex0.match(target_line_value)[1]
    elsif(name_regex2.match?(target_line_value))
      prob_name = name_regex2.match(target_line_value)[1]
    elsif(name_regex3.match?(target_line_value))
      prob_name = name_regex3.match(target_line_value)[2]
      prob_name = name_regex0.match?(prob_name) ? name_regex0.match(prob_name)[1] : prob_name 
    elsif(name_regex1.match?(target_line_value))
      prob_name = name_regex1.match(target_line_value)[1]
    end

    if(!prob_name.nil?)
      prob_name = prob_name[-1] == '.' ? prob_name.chop : prob_name
    end

    while(colon_regex.match?(prob_name))
      prob_name = /::.*?([^.]+)/.match(prob_name)[1]
    end
    find_definition(prob_name, "namespace") != 'Not found' ? find_definition(prob_name, "namespace") : ''
  end

  def handle_missing_names(json)
    bugged = 0
    total = 0
    json["relations"].each_with_index do |dependency, idx|
      total += 1
      if dependency["caller"].empty? && !dependency["file"].empty? && dependency["line"]
        json["relations"][idx]["caller"] = find_missing_name(json["relations"][idx]["file"], json["relations"][idx]["line"])
        bugged += 1
      end
    end
    json
  end

  def read_file(path)
    File.open(path, 'rb') { |file| file.read }
  end

  def write_file(text, path)
    File.open(path, 'w') do |f|
      f.write text
    end
  end

end

#DependenciesExtractor.new.extract("C:/Users/jpms2/Desktop/tg/output.html")
#DependenciesExtractor.new.find_formated_relations('C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\models\user.rb')
#DependenciesExtractor.new.find_all_relations('C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\models\user.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\models\invitation_code.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\lib\diaspora\federated\request.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\models\invitation_code.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\lib\diaspora\federated\request.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\models\user.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\models\user.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\models\invitation_code.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\presenters\user_application_presenter.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\lib\diaspora\federated\request.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\models\user.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\presenters\post_presenter.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\photos_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\streams_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\home_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\tags_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\profiles_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\invitation_codes_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\admin\users_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\users_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\home_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\photos_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\helpers\people_helper.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\streams_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\streams_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\streams_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\models\photo.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\models\invitation_code.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\presenters\user_application_presenter.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\lib\diaspora\federated\request.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\models\user.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\presenters\post_presenter.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\photos_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\streams_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\home_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\tags_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\profiles_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\invitation_codes_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\admin\users_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\users_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\home_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\photos_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\helpers\people_helper.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\streams_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\streams_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\controllers\streams_controller.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\models\photo.rb,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\photos\_index.mobile.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\photos\_new_profile_photo.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\photos\edit.html.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\photos\show.mobile.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\streams\main_stream.html.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\streams\main_stream.mobile.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\home\default.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\home\show.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\tags\show.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\tags\show.mobile.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\profiles\edit.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\profiles\edit.mobile.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\users\edit.html.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\users\edit.mobile.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\devise\passwords\new.haml,C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora\app\views\devise\passwords\new.mobile.haml,diaspora_diaspora\app\views\shared\_right_sections.html.haml,diaspora_diaspora\app\views\people\_index.html.haml,diaspora_diaspora\app\views\publisher\_publisher.html.haml,diaspora_diaspora\app\views\shared\_settings_nav.haml,diaspora_diaspora\app\views\profiles\_edit_public.haml,diaspora_diaspora\app\views\profiles\_edit_private.haml,diaspora_diaspora\app\views\aspects\_aspect_listings.haml,diaspora_diaspora\app\views\tags\_followed_tags_listings.haml,diaspora_diaspora\app\views\aspects\_aspect_stream.haml,diaspora_diaspora\app\views\shared\_stream.haml,diaspora_diaspora\app\views\users\_edit.haml')
#DependenciesExtractor.new.find_definition('C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\TheOdinProject_theodinproject\app\models\user.rb', "file")
#DependenciesExtractor.new.process("C:/Users/jpms2/Desktop/tg/output.html")
#DependenciesExtractor.new.preprocess('C:\Users\jpms2\Desktop\tg\TestInterfaceEvaluation\spg_repos\diaspora_diaspora')